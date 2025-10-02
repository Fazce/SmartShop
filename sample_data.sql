-- Sample data for SmartShop Inventory (small set for testing)

INSERT INTO Categories (CategoryID, CategoryName) VALUES
(1, 'Electronics'),
(2, 'Home'),
(3, 'Kitchen');

INSERT INTO Suppliers (SupplierID, SupplierName, ContactEmail) VALUES
(1, 'ACME Electronics', 'sales@acme.example'),
(2, 'HomeGoods Inc', 'orders@homegoods.example');

INSERT INTO Stores (StoreID, StoreName, Location) VALUES
(1, 'SmartShop Downtown', 'Downtown'),
(2, 'SmartShop Mall', 'Mall');

INSERT INTO Products (ProductID, ProductName, CategoryID, SupplierID, Price, StockLevel) VALUES
(1, 'USB-C Cable', 1, 1, 6.99, 120),
(2, 'Wireless Mouse', 1, 1, 19.99, 45),
(3, 'Coffee Mug', 3, 2, 8.50, 42),
(4, 'Blender', 2, 2, 49.99, 10);

INSERT INTO Inventory (InventoryID, StoreID, ProductID, Quantity) VALUES
(1, 1, 1, 70),
(2, 2, 1, 50),
(3, 1, 2, 20),
(4, 1, 3, 30),
(5, 2, 3, 12),
(6, 2, 4, 10);

INSERT INTO Sales (SaleID, StoreID, ProductID, QuantitySold, UnitPrice, SaleDate) VALUES
(1, 1, 1, 2, 6.99, '2025-09-01'),
(2, 2, 1, 1, 6.99, '2025-09-02'),
(3, 1, 2, 1, 19.99, '2025-09-03');
