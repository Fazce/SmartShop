-- Basic queries for SmartShop Inventory

-- Retrieve product details (ProductName, Category, Price, StockLevel) - simple single-table (if Category stored on Products)
SELECT
  p.ProductName,
  c.CategoryName AS Category,
  p.Price,
  p.StockLevel
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID;

-- Filter by category and availability (in-stock)
SELECT p.ProductName, c.CategoryName AS Category, p.Price, p.StockLevel
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics'
  AND p.StockLevel > 0
ORDER BY p.StockLevel ASC;

-- Product stock per store
SELECT p.ProductName, s.StoreName, i.Quantity AS StockAtStore
FROM Inventory i
JOIN Products p ON i.ProductID = p.ProductID
JOIN Stores s ON i.StoreID = s.StoreID
ORDER BY p.ProductName, s.StoreName;

-- Top-selling products (simple aggregation)
SELECT p.ProductName, SUM(s.QuantitySold) AS TotalSold
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSold DESC;

-- Products in a specific category (by category name)
-- Replace 'Electronics' with the category you want to filter by.
SELECT p.ProductName,
       c.CategoryName AS Category,
       p.Price,
       p.StockLevel
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Parameterized version (use from an app or client that supports parameters)
-- category_name is a placeholder for your client/driver parameter
SELECT p.ProductName, c.CategoryName AS Category, p.Price, p.StockLevel
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = :category_name
ORDER BY p.ProductName;

-- Products with low stock levels (threshold = 10)
-- Change the threshold value as needed.
SELECT p.ProductName,
       COALESCE(c.CategoryName, 'Uncategorized') AS Category,
       p.Price,
       p.StockLevel
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.StockLevel <= 10
ORDER BY p.StockLevel ASC, p.ProductName;

-- Products sorted by Price in ascending order
SELECT p.ProductName,
       COALESCE(c.CategoryName, 'Uncategorized') AS Category,
       p.Price,
       p.StockLevel
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
ORDER BY p.Price ASC, p.ProductName;

-- Combined: Products in a category with low stock, sorted by Price ASC
SELECT p.ProductName,
       c.CategoryName AS Category,
       p.Price,
       p.StockLevel
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics' -- or use :category_name
  AND p.StockLevel <= 10
ORDER BY p.Price ASC;

-- Multi-table JOIN & reports

-- Join Products, Sales, Suppliers, and Stores
-- Shows ProductName, SaleDate, StoreLocation, and UnitsSold (QuantitySold)
SELECT
  p.ProductName,
  s.SaleDate,
  st.Location     AS StoreLocation,
  s.QuantitySold  AS UnitsSold,
  sup.SupplierName
FROM Sales s
JOIN Products p   ON s.ProductID = p.ProductID
JOIN Stores st    ON s.StoreID = st.StoreID
LEFT JOIN Suppliers sup ON p.SupplierID = sup.SupplierID
ORDER BY s.SaleDate DESC, p.ProductName;

-- Sales trends: units sold per product by date and store (parameterize date range)
WITH sales_daily_store AS (
  SELECT
    ProductID,
    StoreID,
    DATE(SaleDate) AS SaleDay,
    SUM(QuantitySold) AS UnitsSold
  FROM Sales
  WHERE SaleDate BETWEEN :start_date AND :end_date
  GROUP BY ProductID, StoreID, DATE(SaleDate)
)
SELECT
  p.ProductName,
  sd.SaleDay   AS SaleDate,
  st.Location  AS StoreLocation,
  sd.UnitsSold
FROM sales_daily_store sd
JOIN Products p ON sd.ProductID = p.ProductID
JOIN Stores st ON sd.StoreID = st.StoreID
ORDER BY sd.SaleDay ASC, sd.UnitsSold DESC;

-- Top-performing suppliers by total stock across stores (using Inventory)
SELECT
  sup.SupplierName,
  SUM(i.Quantity)                AS TotalStockAcrossStores,
  COUNT(DISTINCT p.ProductID)    AS ProductsSupplied
FROM Suppliers sup
JOIN Products p ON p.SupplierID = sup.SupplierID
JOIN Inventory i ON i.ProductID = p.ProductID
GROUP BY sup.SupplierName
ORDER BY TotalStockAcrossStores DESC;

-- Supplier ranking using product-level StockLevel (denormalized)
SELECT
  sup.SupplierName,
  SUM(COALESCE(p.StockLevel,0))  AS TotalReportedStock,
  COUNT(p.ProductID)             AS ProductsSupplied
FROM Suppliers sup
JOIN Products p ON p.SupplierID = sup.SupplierID
GROUP BY sup.SupplierName
ORDER BY TotalReportedStock DESC;

-- Supplier rank with window function (if supported by your DB)
SELECT
  SupplierName,
  TotalStockAcrossStores,
  RANK() OVER (ORDER BY TotalStockAcrossStores DESC) AS SupplierRank
FROM (
  SELECT sup.SupplierName, SUM(i.Quantity) AS TotalStockAcrossStores
  FROM Suppliers sup
  JOIN Products p ON p.SupplierID = sup.SupplierID
  JOIN Inventory i ON i.ProductID = p.ProductID
  GROUP BY sup.SupplierName
) t;

-- Consolidated inventory across stores (per product totals)
SELECT
  p.ProductName,
  SUM(i.Quantity)            AS TotalQuantityAcrossStores,
  MIN(i.LastUpdated)         AS LastInventoryUpdate
FROM Inventory i
JOIN Products p ON i.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalQuantityAcrossStores ASC, p.ProductName;

-- Detailed per-product, per-store inventory
SELECT
  p.ProductName,
  st.StoreName,
  st.Location,
  i.Quantity,
  i.LastUpdated
FROM Inventory i
JOIN Products p ON i.ProductID = p.ProductID
JOIN Stores st ON i.StoreID = st.StoreID
ORDER BY p.ProductName, st.StoreName;

-- End of multi-table reports

-- Nested queries & aggregation

-- Total sales for each product (aggregation with GROUP BY)
-- Returns total units sold and total revenue per product
SELECT
  p.ProductID,
  p.ProductName,
  SUM(COALESCE(s.QuantitySold,0))                 AS TotalUnitsSold,
  SUM(COALESCE(s.QuantitySold,0) * COALESCE(s.UnitPrice,0)) AS TotalRevenue
FROM Products p
LEFT JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalUnitsSold DESC;

-- Identify suppliers with the most delayed deliveries
/* Assumes Deliveries(DeliveryID, SupplierID, ProductID, ExpectedDate, DeliveredDate, Quantity)
*/
/* SQLite variant using julianday() */
SELECT
  sup.SupplierID,
  sup.SupplierName,
  COUNT(*) AS DelayedDeliveries,
  AVG(julianday(d.DeliveredDate) - julianday(d.ExpectedDate)) AS AvgDelayDays
FROM Deliveries d
JOIN Suppliers sup ON d.SupplierID = sup.SupplierID
WHERE d.DeliveredDate IS NOT NULL AND d.DeliveredDate > d.ExpectedDate
GROUP BY sup.SupplierID, sup.SupplierName
ORDER BY DelayedDeliveries DESC;

/* SQL Server variant using DATEDIFF */
SELECT
  sup.SupplierID,
  sup.SupplierName,
  COUNT(*) AS DelayedDeliveries,
  AVG(DATEDIFF(day, d.ExpectedDate, d.DeliveredDate)) AS AvgDelayDays
FROM Deliveries d
JOIN Suppliers sup ON d.SupplierID = sup.SupplierID
WHERE d.DeliveredDate IS NOT NULL AND d.DeliveredDate > d.ExpectedDate
GROUP BY sup.SupplierID, sup.SupplierName
ORDER BY DelayedDeliveries DESC;

/* Treat undelivered items as delayed if past expected date (SQLite example) */
SELECT
  sup.SupplierID,
  sup.SupplierName,
  SUM(CASE WHEN (d.DeliveredDate IS NOT NULL AND d.DeliveredDate > d.ExpectedDate)
             OR (d.DeliveredDate IS NULL AND DATE('now') > DATE(d.ExpectedDate))
           THEN 1 ELSE 0 END) AS DelayedOrOverdueCount
FROM Suppliers sup
JOIN Deliveries d ON d.SupplierID = sup.SupplierID
GROUP BY sup.SupplierID, sup.SupplierName
ORDER BY DelayedOrOverdueCount DESC;

-- Useful aggregate examples (SUM, AVG, MAX, MIN) for sales and pricing
-- Average unit price sold per product
SELECT
  p.ProductID,
  p.ProductName,
  AVG(s.UnitPrice) AS AvgSoldUnitPrice
FROM Products p
JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgSoldUnitPrice DESC;

-- Max single-sale quantity per product
SELECT
  p.ProductID,
  p.ProductName,
  MAX(s.QuantitySold) AS MaxQuantityInSingleSale
FROM Products p
JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY MaxQuantityInSingleSale DESC;

-- Combined example: products with total revenue and average daily sales (simple approximation)
-- Average daily sales computed over a date span using a subquery for the date range per product
SELECT
  totals.ProductID,
  totals.ProductName,
  totals.TotalRevenue,
  ROUND(totals.TotalRevenue / NULLIF(days.SpanDays,0),2) AS AvgRevenuePerDay
FROM (
  SELECT p.ProductID, p.ProductName, SUM(s.QuantitySold * s.UnitPrice) AS TotalRevenue
  FROM Products p
  LEFT JOIN Sales s ON s.ProductID = p.ProductID
  GROUP BY p.ProductID, p.ProductName
) totals
CROSS JOIN (
  -- overall time span for sales in the dataset (use DATE functions appropriate for your DB)
  SELECT
  DATE(s.SaleDate) AS SaleDate,
  SUM(COALESCE(s.QuantitySold,0)) AS UnitsSold,
  AVG(COALESCE(s.UnitPrice,0)) AS AvgUnitPrice,
  MAX(COALESCE(s.UnitPrice,0)) AS MaxUnitPrice
  FROM Sales s
  WHERE s.SaleDate BETWEEN :start_date AND :end_date
  GROUP BY DATE(s.SaleDate)
  ORDER BY SaleDate;
) days
ORDER BY totals.TotalRevenue DESC;

-- End of nested queries & aggregation examples
