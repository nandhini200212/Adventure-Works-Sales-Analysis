use adventures;
/*0. Union of Fact Internet sales and Fact internet sales new*/
create table  sales as select * from factinternetsales union all
select * from fact_internet_sales_new;
select * from sales;

/*1.Lookup the productname from the Product sheet to Sales sheet.*/
select s.*,p.englishproductname from sales s left join dimproduct p on s.productkey=p.ProductKey;

/*2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.*/
select concat(c.firstname, ' ',c.lastname) as customerfullname,p.englishproductname,s.UnitPrice from sales s
left join dimcustomer c on s.CustomerKey=c.CustomerKey left join dimproduct p on  s.ProductKey=p.ProductKey;

/*3.calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey) */
select orderdatekey, str_to_date(orderdatekey,'%y%m%d') as orderdate from sales;
select  YEAR(STR_TO_DATE(orderdatekey, '%Y%m%d')) AS year,  Month(str_to_date(orderdatekey,'%y%m%d')) as  month_no,
monthname(str_to_date(orderdatekey,'%y%m%d')) as month_fullname,CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d'))) AS Quarter,
DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'), '%Y-%b') AS YearMonth,DAYOFWEEK(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Weekday_No,
DAYNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Weekday_Name,OrderDateKey,
month(str_to_date(orderdatekey,'%y%m%d')) as Actual_month,
case when month(str_to_date(orderdatekey,'%y%m%d'))>=4 then month(str_to_date(orderdatekey,'%y%m%d'))-3 
else month(str_to_date(orderdatekey,'%y%m%d'))+9 end as Financial_month,
case when
(case when  month(str_to_date(orderdatekey,'%y%m%d')) >=4 
 then month(str_to_date(orderdatekey,'%y%m%d')) -3
 else month(str_to_date(orderdatekey,'%y%m%d')) +9
 End) between 1 and 6 then 'Q1'
 else 'Q2' 
 end as Financial_Quarter
 from sales ;

/*4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)*/
 SELECT 
    orderquantity,
    unitprice,
    orderquantity * unitprice AS SalesAmount
FROM sales;

/*5.Calculate the Productioncost uning the columns(unit cost ,order quantity)*/
select s.ProductKey,p.standardcost,s.OrderQuantity,(p.standardcost*s.OrderQuantity) as ProductionCost
from sales s join dimproduct p on s.ProductKey=p.ProductKey;

/*6.Calculate the profit.*/
SELECT salesamount-ProductStandardCost from sales;

/*7.Create a Pivot table for month and sales (provide the Year as filter to select a particular Year)*/
SELECT 
    MONTHNAME(orderdate) AS Month,
    SUM(orderquantity * unitprice) AS TotalSales
FROM sales
GROUP BY MONTH(orderdate), MONTHNAME(orderdate)
ORDER BY MONTH(orderdate);

/*8.Create a Bar chart to show yearwise Sales*/
SELECT 
    YEAR(orderdate) AS Year,
    SUM(orderquantity * unitprice) AS TotalSales
FROM sales
GROUP BY YEAR(orderdate)
ORDER BY Year;

/*9.Create a Line Chart to show Monthwise sales*/
SELECT 
    MONTHNAME(orderdate) AS Month,
    SUM(orderquantity * unitprice) AS TotalSales
FROM sales
GROUP BY MONTH(orderdate), MONTHNAME(orderdate)
ORDER BY MONTH(orderdate);

/*10.Create a Pie chart to show Quarterwise sales*/
select 
concat('Q' , Quarter(orderdate)) as quarter,
sum(orderquantity  * unitprice * (1- discountamount)) as totalsales from sales
group by  Quarter(orderdate), concat('Q',quarter(orderdate))
order by quarter(orderdate);

/*11.Create a combinational chart (bar and Line) to show Salesamount and Productioncost together*/
SELECT 
    YEAR(orderdate) AS Year,
    SUM(orderquantity * unitprice) AS Sales,
    SUM((orderquantity * unitprice) - (orderquantity * ProductStandardCost)) AS Profit
FROM sales
GROUP BY YEAR(orderdate);

/*12.Build addtional KPI /Charts for Performance by Products, Customers, Region*/
SELECT 
    SUM(orderquantity * unitprice) AS TotalSales,
    SUM(orderquantity * productstandardcost) AS TotalCost,
    SUM((orderquantity * unitprice) - (orderquantity * productstandardcost)) AS TotalProfit,
    ROUND(
        SUM((orderquantity * unitprice) - (orderquantity * productstandardcost)) /
        SUM(orderquantity * unitprice) * 100, 2
    ) AS ProfitPercent
FROM sales;


/*Product performance*/
SELECT 
    p.ProductAlternateKey AS Product,
    SUM(s.OrderQuantity * s.UnitPrice) AS TotalSales
FROM sales s
LEFT JOIN dimproduct p
ON s.ProductKey = p.ProductKey
GROUP BY p.ProductAlternateKey
ORDER BY TotalSales DESC;
/*Customer Performance*/
SELECT 
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(s.OrderQuantity * s.UnitPrice) AS TotalSales
FROM sales s
LEFT JOIN dimcustomer c
ON s.CustomerKey = c.CustomerKey
GROUP BY CustomerName
ORDER BY TotalSales DESC;
/*Region performance*/
SELECT 
    t.SalesTerritoryRegion AS Region,
    SUM(s.SalesAmount) AS TotalSales
FROM sales s
LEFT JOIN dimsalesterritory t
ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryRegion
ORDER BY TotalSales DESC;
 