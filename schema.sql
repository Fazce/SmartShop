-- SmartShop Inventory schema (generic SQL - adapt types for your DBMS)

CREATE TABLE Categories (
  CategoryID INTEGER PRIMARY KEY,
  CategoryName TEXT NOT NULL
);

CREATE TABLE Suppliers (
  SupplierID INTEGER PRIMARY KEY,
  SupplierName TEXT NOT NULL,
  ContactEmail TEXT
);

CREATE TABLE Stores (
  StoreID INTEGER PRIMARY KEY,
  StoreName TEXT NOT NULL,
  Location TEXT
);

CREATE TABLE Products (
  ProductID INTEGER PRIMARY KEY,
  ProductName TEXT NOT NULL,
  CategoryID INTEGER,
  SupplierID INTEGER,
  Price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  -- current aggregated stock level (optional, denormalized for speed)
  StockLevel INTEGER DEFAULT 0,
  FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
  FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Inventory per store (normalized stock per store)
CREATE TABLE Inventory (
  InventoryID INTEGER PRIMARY KEY,
  StoreID INTEGER NOT NULL,
  ProductID INTEGER NOT NULL,
  Quantity INTEGER NOT NULL DEFAULT 0,
  LastUpdated DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
  FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Sales transactions (simple model)
CREATE TABLE Sales (
  SaleID INTEGER PRIMARY KEY,
  StoreID INTEGER NOT NULL,
  ProductID INTEGER NOT NULL,
  QuantitySold INTEGER NOT NULL,
  SaleDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  UnitPrice DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
  FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create indexes on columns used in JOINs, WHERE filters and ORDER BY
CREATE INDEX IF NOT EXISTS idx_sales_productid ON Sales(ProductID);
CREATE INDEX IF NOT EXISTS idx_sales_saledate ON Sales(SaleDate);
CREATE INDEX IF NOT EXISTS idx_sales_storeid ON Sales(StoreID);
CREATE INDEX IF NOT EXISTS idx_sales_productid_saledate ON Sales(ProductID, SaleDate);

CREATE INDEX IF NOT EXISTS idx_inventory_productid_storeid ON Inventory(ProductID, StoreID);

CREATE INDEX IF NOT EXISTS idx_products_supplierid ON Products(SupplierID);
CREATE INDEX IF NOT EXISTS idx_categories_name ON Categories(CategoryName);

-- For if adding Deliveries table, or if the Deliveries table exists:
CREATE INDEX IF NOT EXISTS idx_deliveries_supplier_expected ON Deliveries(SupplierID, ExpectedDate);
CREATE INDEX IF NOT EXISTS idx_deliveries_delivereddate ON Deliveries(DeliveredDate);

