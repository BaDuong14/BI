CREATE DATABASE retail_dw;
USE retail_dw;

-- 2. TẠO BẢNG STAGING (Phải khớp chính xác số lượng và thứ tự cột trong CSV)
CREATE TABLE staging_table (
    Row_ID INT,
    Order_ID VARCHAR(50),
    Order_Date VARCHAR(20), -- Để VARCHAR để convert sau
    Ship_Date VARCHAR(20),
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(255),
    Segment VARCHAR(100),
    Country VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    Postal_Code VARCHAR(20),
    Region VARCHAR(100),
    Product_ID VARCHAR(50),
    Category VARCHAR(100),
    Sub_Category VARCHAR(100),
    Product_Name VARCHAR(255),
    Sales DECIMAL(15,4),
    Quantity INT,
    Discount DECIMAL(15,4),
    Profit DECIMAL(15,4)
);
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Dim_Product;
CREATE TABLE Dim_Product (
    Product_Key INT AUTO_INCREMENT PRIMARY KEY,
    Original_Product_ID VARCHAR(50),
    Product_Name VARCHAR(255),
    Category VARCHAR(100),
    Sub_Category VARCHAR(100)
);

DROP TABLE IF EXISTS Dim_Customer;
CREATE TABLE Dim_Customer (
    Customer_Key INT AUTO_INCREMENT PRIMARY KEY,
    Original_Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(255),
    Segment VARCHAR(100)
);

DROP TABLE IF EXISTS Dim_Time;
CREATE TABLE Dim_Time (
    Time_Key INT AUTO_INCREMENT PRIMARY KEY,
    Order_Date DATE,
    Day INT,
    Month INT,
    Quarter INT,
    Year INT
);

DROP TABLE IF EXISTS Dim_Location;
CREATE TABLE Dim_Location (
    Location_Key INT AUTO_INCREMENT PRIMARY KEY,
    Country VARCHAR(100),
    Region VARCHAR(100),
    State VARCHAR(100),
    City VARCHAR(100),
    Postal_Code VARCHAR(20)
);

-- 3. Tạo bảng Fact_Sales (Dùng chính xác tên các bảng vừa tạo ở trên)
DROP TABLE IF EXISTS Fact_Sales;
CREATE TABLE Fact_Sales (
    Sales_ID INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID VARCHAR(50),
    Product_Key INT,
    Customer_Key INT,
    Time_Key INT,
    Location_Key INT,
    Sales DECIMAL(15,4),
    Quantity INT,
    Discount DECIMAL(15,4),
    Profit DECIMAL(15,4),
    CONSTRAINT fk_product FOREIGN KEY (Product_Key) REFERENCES Dim_Product(Product_Key),
    CONSTRAINT fk_customer FOREIGN KEY (Customer_Key) REFERENCES Dim_Customer(Customer_Key),
    CONSTRAINT fk_time FOREIGN KEY (Time_Key) REFERENCES Dim_Time(Time_Key),
    CONSTRAINT fk_location FOREIGN KEY (Location_Key) REFERENCES Dim_Location(Location_Key)
);

-- 4. Bật lại kiểm tra khóa ngoại
SET FOREIGN_KEY_CHECKS = 1;
-- Nạp lại dữ liệu vào các bảng Dim
-- 1. Nạp dữ liệu vào Dim_Product
INSERT INTO Dim_Product (Original_Product_ID, Product_Name, Category, Sub_Category)
SELECT DISTINCT Product_ID, Product_Name, Category, Sub_Category 
FROM staging_table;

-- 2. Nạp dữ liệu vào Dim_Customer
INSERT INTO Dim_Customer (Original_Customer_ID, Customer_Name, Segment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment 
FROM staging_table;

-- 3. Nạp dữ liệu vào Dim_Time
INSERT INTO Dim_Time (Order_Date, Day, Month, Quarter, Year)
SELECT DISTINCT 
    STR_TO_DATE(Order_Date, '%m/%d/%Y'), 
    DAY(STR_TO_DATE(Order_Date, '%m/%d/%Y')), 
    MONTH(STR_TO_DATE(Order_Date, '%m/%d/%Y')), 
    QUARTER(STR_TO_DATE(Order_Date, '%m/%d/%Y')), 
    YEAR(STR_TO_DATE(Order_Date, '%m/%d/%Y'))
FROM staging_table;
-- 4. Nạp dữ liệu vào Dim_Location
INSERT INTO Dim_Location (Country, Region, State, City, Postal_Code)
SELECT DISTINCT Country, Region, State, City, Postal_Code 
FROM staging_table;

-- 5. Nạp dữ liệu vào Fact_Sales (Dùng JOIN chính xác tên cột có gạch dưới)
INSERT INTO Fact_Sales (Order_ID, Product_Key, Customer_Key, Time_Key, Location_Key, Sales, Quantity, Discount, Profit)
SELECT 
    s.Order_ID, p.Product_Key, c.Customer_Key, t.Time_Key, l.Location_Key,
    s.Sales, s.Quantity, s.Discount, s.Profit
FROM staging_table s
JOIN Dim_Product p ON s.Product_ID = p.Original_Product_ID AND s.Product_Name = p.Product_Name
JOIN Dim_Customer c ON s.Customer_ID = c.Original_Customer_ID
JOIN Dim_Time t ON STR_TO_DATE(s.Order_Date, '%m/%d/%Y') = t.Order_Date
JOIN Dim_Location l ON s.Postal_Code = l.Postal_Code AND s.City = l.City;

-- KIỂM TRA KẾT QUẢ
SELECT * FROM Fact_Sales LIMIT 10;