// scripts/update-token.js
/**
 * Script to fetch WoW token prices from the official Blizzard API
 * Requires client ID and secret from the Blizzard Developer Portal
 */
const https = require('https');
const fs = require('fs');
const path = require('path');
const querystring = require('querystring');

// Configuration - Updated path for the new structure
const OUTPUT_FILE = path.join(__dirname, '..', 'src', 'Generated', 'TokenPrices.lua');

// Blizzard API credentials (to be filled in)
const CLIENT_ID = process.env.BLIZZARD_CLIENT_ID || '';
const CLIENT_SECRET = process.env.BLIZZARD_CLIENT_SECRET || '';

// Token prices in real currency (fixed values set by Blizzard)
const TOKEN_REAL_PRICES = {
	US: { price: 20, currency: "USD" },
	EU: { price: 20, currency: "EUR" },
	KR: { price: 22000, currency: "KRW" },
	TW: { price: 500, currency: "TWD" }
};

// Mapping of API regions to our internal region codes
const REGION_MAPPING = {
	'us': 'US',
	'eu': 'EU',
	'kr': 'KR',
	'tw': 'TW'
};

// API endpoints by region
const API_REGIONS = {
	'us': 'https://us.api.blizzard.com',
	'eu': 'https://eu.api.blizzard.com',
	'kr': 'https://kr.api.blizzard.com',
	'tw': 'https://tw.api.blizzard.com'
};

// Get current date in YYYY-MM-DD format
const today = new Date();
const dateString = today.toISOString().split('T')[0];

// Fallback token data in case API is unavailable
const FALLBACK_TOKEN_DATA = {
	US: {
		goldPrice: 245750,
		realPrice: 20,
		currency: "USD",
		goldValue: 20 / 245750,
	},
	EU: {
		goldPrice: 313420,
		realPrice: 20,
		currency: "EUR",
		goldValue: 20 / 313420,
	},
	KR: {
		goldPrice: 176420,
		realPrice: 22000,
		currency: "KRW",
		goldValue: 22000 / 176420,
	},
	TW: {
		goldPrice: 184260,
		realPrice: 500,
		currency: "TWD",
		goldValue: 500 / 184260,
	},
};

// Let's try an alternative approach using axios for easier HTTP requests
const axios = require('axios').default;

/**
 * Get OAuth access token from Blizzard API using axios
 * @returns {Promise<string>} - Access token
 */
async function getOAuthToken() {
	try {
		console.log('Getting OAuth token from Blizzard API...');
		console.log(`Using Client ID: ${CLIENT_ID.substring(0, 5)}...`);

		const tokenUrl = 'https://oauth.battle.net/token';
		const params = new URLSearchParams();
		params.append('grant_type', 'client_credentials');

		console.log(`OAuth request to: ${tokenUrl}`);

		const response = await axios.post(tokenUrl, params, {
			auth: {
				username: CLIENT_ID,
				password: CLIENT_SECRET
			},
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded'
			}
		});

		console.log(`OAuth response status: ${response.status}`);

		if (response.data && response.data.access_token) {
			console.log(`Successfully obtained OAuth token: ${response.data.access_token.substring(0, 10)}...`);
			return response.data.access_token;
		} else {
			throw new Error('No access token in response');
		}
	} catch (error) {
		console.error('Error getting OAuth token:', error.message);
		if (error.response) {
			console.error('Response data:', error.response.data);
			console.error('Response status:', error.response.status);
		}
		throw new Error(`Failed to get OAuth token: ${error.message}`);
	}
}

/**
 * Fetch token price from Blizzard API for a specific region using axios
 * @param {string} apiRegion - API region code (us, eu, kr, tw)
 * @param {string} accessToken - OAuth access token
 * @returns {Promise<number|null>} - Token price in gold or null if not found
 */
async function fetchTokenPrice(apiRegion, accessToken) {
	try {
		console.log(`Fetching token price for ${apiRegion} region...`);

		const apiBaseUrl = API_REGIONS[apiRegion];
		const url = `${apiBaseUrl}/data/wow/token/index`;

		console.log(`Requesting: ${url} with namespace dynamic-${apiRegion}`);

		const response = await axios.get(url, {
			headers: {
				'Authorization': `Bearer ${accessToken}`,
				'Content-Type': 'application/json'
			},
			params: {
				'namespace': `dynamic-${apiRegion}`,
				'locale': 'en_US'
			}
		});

		console.log(`Response status for ${apiRegion}: ${response.status}`);
		console.log(`Response data for ${apiRegion}:`, JSON.stringify(response.data));

		if (response.data && response.data.price) {
			// Blizzard returns price in copper, convert to gold
			// 1 gold = 100 silver = 10000 copper
			const goldPrice = Math.round(response.data.price / 10000);
			console.log(`${apiRegion.toUpperCase()} token price: ${goldPrice} gold (${response.data.price} copper)`);
			return goldPrice;
		} else {
			console.warn(`Warning: Could not find price property in response for ${apiRegion}`);
			if (response.data) {
				console.warn(`Response keys: ${Object.keys(response.data).join(', ')}`);
			}
			return null;
		}
	} catch (error) {
		console.warn(`Error fetching token data for ${apiRegion}: ${error.message}`);
		if (error.response) {
			console.warn(`Status: ${error.response.status}`);
			console.warn(`Data: ${JSON.stringify(error.response.data)}`);
		}
		return null;
	}
}

/**
 * Fetch token prices for all regions
 * @returns {Promise<Object>} - Token data by region
 */
async function fetchAllTokenPrices() {
	try {
		// Get OAuth token
		const accessToken = await getOAuthToken();

		// Fetch token prices for each region
		const tokenData = {};

		for (const [apiRegion, apiUrl] of Object.entries(API_REGIONS)) {
			const region = REGION_MAPPING[apiRegion];

			try {
				const goldPrice = await fetchTokenPrice(apiRegion, accessToken);

				if (goldPrice) {
					const realPrice = TOKEN_REAL_PRICES[region].price;
					const currency = TOKEN_REAL_PRICES[region].currency;

					tokenData[region] = {
						goldPrice,
						realPrice,
						currency,
						goldValue: realPrice / goldPrice
					};
				} else {
					console.warn(`Using fallback data for ${region}`);
					tokenData[region] = FALLBACK_TOKEN_DATA[region];
				}
			} catch (err) {
				console.warn(`Error fetching token price for ${region}: ${err.message}`);
				console.warn(`Using fallback data for ${region}`);
				tokenData[region] = FALLBACK_TOKEN_DATA[region];
			}
		}

		return tokenData;
	} catch (err) {
		console.error(`Error fetching token prices: ${err.message}`);
		console.warn('Using fallback token data for all regions');
		return FALLBACK_TOKEN_DATA;
	}
}

/**
 * Generate Lua code for token data
 * @param {Object} tokenData - Token data by region
 * @returns {string} - Generated Lua code
 */
function generateLuaCode(tokenData) {
	let luaTable = `-- Auto-generated token price data\n`;
	luaTable += `-- Last updated: ${dateString}\n\n`;
	luaTable += `PeaversCurrencyData = PeaversCurrencyData or {}\n\n`;
	luaTable += `-- WoW Token prices across regions\n`;
	luaTable += `PeaversCurrencyData.TokenPrices = {\n`;
	luaTable += `  lastUpdated = "${dateString}",\n\n`;
	luaTable += `  regions = {\n`;

	// Add token data for each region
	for (const [region, data] of Object.entries(tokenData)) {
		luaTable += `    ${region} = {\n`;
		luaTable += `      goldPrice = ${Math.round(data.goldPrice)},  -- Gold cost of a token\n`;
		luaTable += `      realPrice = ${data.realPrice},      -- ${data.currency} cost of a token\n`;
		luaTable += `      currency = "${data.currency}",\n`;
		luaTable += `      goldValue = ${data.goldValue.toFixed(10)}, -- ${data.currency} value of 1 gold\n`;
		luaTable += `    },\n`;
	}

	luaTable += `  }\n`;
	luaTable += `}\n`;

	return luaTable;
}

/**
 * Main function to run the script
 */
async function main() {
	try {
		console.log("Script started - fetching WoW token prices from Blizzard API");

		// First, make sure we have the axios library installed
		try {
			require.resolve('axios');
			console.log("Axios is installed and ready to use");
		} catch (e) {
			console.error("Axios is not installed. Please run 'npm install axios' first.");
			process.exit(1);
		}

		// Ensure the output directory exists
		const dir = path.dirname(OUTPUT_FILE);
		if (!fs.existsSync(dir)) {
			fs.mkdirSync(dir, { recursive: true });
			console.log(`Created directory: ${dir}`);
		}

		// Fetch token data
		const tokenData = await fetchAllTokenPrices();

		// Generate Lua code
		const luaCode = generateLuaCode(tokenData);

		// Write to file
		fs.writeFileSync(OUTPUT_FILE, luaCode);
		console.log(`Token data successfully written to ${OUTPUT_FILE}`);
	} catch (error) {
		console.error('Error:', error.message);
		process.exit(1);
	}
}

// Run the script
main();
