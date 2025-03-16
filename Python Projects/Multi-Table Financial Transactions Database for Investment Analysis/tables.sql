CREATE TABLE investors (
    investor_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE portfolios (
    portfolio_id SERIAL PRIMARY KEY,
    investor_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (investor_id) REFERENCES investors(investor_id) ON DELETE CASCADE
);

CREATE TABLE stock_transactions (
    transaction_id SERIAL PRIMARY KEY,
    portfolio_id INT NOT NULL,
    stock_symbol VARCHAR(10) NOT NULL,
    transaction_type VARCHAR(4) CHECK (transaction_type IN ('BUY', 'SELL')),
    shares INT CHECK (shares > 0),
    price_per_share FLOAT CHECK (price_per_share > 0),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id) ON DELETE CASCADE
);

CREATE TABLE stock_prices (
    stock_symbol VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    open_price FLOAT CHECK (open_price > 0),
    high_price FLOAT CHECK (high_price > 0),
    low_price FLOAT CHECK (low_price > 0),
    close_price FLOAT CHECK (close_price > 0),
    volume BIGINT CHECK (volume >= 0),
    PRIMARY KEY (stock_symbol, date)
);

DROP TABLE IF EXISTS market_indices;

CREATE TABLE market_indices (
    index_id VARCHAR(10) NOT NULL,  -- e.g., "^GSPC" for S&P 500
    index_name VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    closing_value FLOAT NOT NULL,
    PRIMARY KEY (index_id, date)
);

SELECT * FROM market_indices;

SELECT DISTINCT stock_symbol FROM stock_prices WHERE stock_symbol LIKE '%SP%';
