// scripts/update-currency.js
/**
 * Script to fetch and update currency exchange rates
 * This script fetches data from the Fawaz Ahmed Currency API and formats it as a Lua file
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration - Updated path for the new structure
const OUTPUT_FILE = path.join(__dirname, '..', 'src', 'Generated', 'CurrencyRates.lua');
const API_URL = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json';
const MAJOR_CURRENCIES = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'HKD', 'NZD', 'KRW', 'TWD'];

// Get current date in YYYY-MM-DD format
const today = new Date();
const dateString = today.toISOString().split('T')[0];

/**
 * Fetch currency data from the API
 * @returns {Promise<string>} - The generated Lua code
 */
async function fetchCurrencyData() {
    return new Promise((resolve, reject) => {
        console.log(`Fetching currency data from ${API_URL}...`);

        https.get(API_URL, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', async () => {
                try {
                    const currencyData = JSON.parse(data);
                    console.log('Successfully fetched USD currency data');

                    // Start building Lua table - CLEANER FORMAT
                    let luaTable = `-- Auto-generated currency exchange rates\n`;
                    luaTable += `-- Last updated: ${dateString}\n\n`;
                    luaTable += `PeaversCurrencyData = PeaversCurrencyData or {}\n`;
                    luaTable += `PeaversCurrencyData.CurrencyRates = {\n`;
                    luaTable += `  lastUpdated = "${dateString}",\n\n`;

                    // Add rates
                    luaTable += `  rates = {\n`;

                    // Add USD as base currency first
                    luaTable += `    USD = {\n`;

                    // Add USD rates
                    for (const currency in currencyData.usd) {
                        const currencyCode = currency.toUpperCase();
                        if (MAJOR_CURRENCIES.includes(currencyCode)) {
                            luaTable += `      ${currencyCode} = ${currencyData.usd[currency]},\n`;
                        }
                    }
                    luaTable += `    },\n`;

                    // Fetch and add other base currencies
                    const currencySections = await fetchOtherCurrencies();
                    for (const section of currencySections) {
                        luaTable += section;
                    }

                    luaTable += `  },\n\n`;

                    // Add symbols
                    luaTable += `  symbols = {\n`;
                    luaTable += `    USD = "$",\n`;
                    luaTable += `    EUR = "€",\n`;
                    luaTable += `    GBP = "£",\n`;
                    luaTable += `    JPY = "¥",\n`;
                    luaTable += `    CAD = "C$",\n`;
                    luaTable += `    AUD = "A$",\n`;
                    luaTable += `    CHF = "Fr",\n`;
                    luaTable += `    CNY = "¥",\n`;
                    luaTable += `    HKD = "HK$",\n`;
                    luaTable += `    NZD = "NZ$",\n`;
                    luaTable += `    KRW = "₩",\n`;
                    luaTable += `    TWD = "NT$",\n`;
                    luaTable += `  }\n`;
                    luaTable += `}\n`;

                    resolve(luaTable);
                } catch (err) {
                    reject(new Error(`Error parsing currency data: ${err.message}`));
                }
            });
        }).on('error', (err) => {
            reject(new Error(`Error fetching currency data: ${err.message}`));
        });
    });
}

/**
 * Fetch exchange rates for additional base currencies
 * @returns {Promise<string[]>} - Array of Lua code sections for each currency
 */
async function fetchOtherCurrencies() {
    // Skip USD since we already handled it
    const currenciesToFetch = MAJOR_CURRENCIES.slice(1);

    const promises = currenciesToFetch.map(currency => {
        return new Promise((resolve, reject) => {
            const currencyApiUrl = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/${currency.toLowerCase()}.json`;

            https.get(currencyApiUrl, (currencyRes) => {
                let currencyRateData = '';

                currencyRes.on('data', (chunk) => {
                    currencyRateData += chunk;
                });

                currencyRes.on('end', () => {
                    try {
                        const currencyRates = JSON.parse(currencyRateData);
                        const baseCurrency = currency.toUpperCase();
                        console.log(`Successfully fetched ${baseCurrency} currency data`);

                        let currencySection = `    ${baseCurrency} = {\n`;

                        for (const targetCurrency in currencyRates[currency.toLowerCase()]) {
                            const targetCode = targetCurrency.toUpperCase();
                            if (MAJOR_CURRENCIES.includes(targetCode)) {
                                currencySection += `      ${targetCode} = ${currencyRates[currency.toLowerCase()][targetCurrency]},\n`;
                            }
                        }

                        currencySection += `    },\n`;
                        resolve(currencySection);
                    } catch (err) {
                        console.warn(`Warning: Error fetching ${currency} data: ${err.message}`);
                        resolve(`    ${currency.toUpperCase()} = {}, -- Failed to fetch\n`);
                    }
                });
            }).on('error', (err) => {
                console.warn(`Warning: Error fetching ${currency} data: ${err.message}`);
                resolve(`    ${currency.toUpperCase()} = {}, -- Failed to fetch\n`);
            });
        });
    });

    try {
        return await Promise.all(promises);
    } catch (err) {
        console.error('Error fetching other currencies:', err);
        return []; // Return empty array if we couldn't fetch others
    }
}

/**
 * Main function to run the script
 */
async function main() {
    try {
        // Ensure the output directory exists
        const dir = path.dirname(OUTPUT_FILE);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
            console.log(`Created directory: ${dir}`);
        }

        // Fetch and generate the currency data
        const luaCode = await fetchCurrencyData();

        // Write to file
        fs.writeFileSync(OUTPUT_FILE, luaCode);
        console.log(`Currency data successfully written to ${OUTPUT_FILE}`);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Run the script
main();