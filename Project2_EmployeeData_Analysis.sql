/* Project 2 - Employee data analysis and dashboard visualization */

/*using employees table for analysis */
use employees;

/* using describe for getting name of fields in table, column datatype*/
describe employees;

/* using select statement for quering data */
select * from employees;
select firstname,jobtitle,salary from employees;


/* sorting data using order by */
/* The ORDER BY clause is evaluated after the FROM and SELECT clauses */
/* from > select > order by */
/* use-case-1 : sorting the employees data in ascending order by lastname */
select firstname,lastname from employees 
order by lastname;
/* use-case-2: using multiple columns for sorting - in case of same names the last name is used for sorting */
select firstname,lastname from employees 
order by firstName asc,lastname asc;
/* use-case-3: Using the ORDER BY clause to sort a result set by an expression */
select firstname,jobtitle,salary*12 as Annualsalary from employees 
order by annualsalary desc;


/* Filtering the employees data for analysis */
/* When executing a SELECT statement with a WHERE clause, MySQL evaluates the WHERE clause after the FROM clause */
/*and before the SELECT and ORDER BY clauses*/
/* from > where > select> order by */
/* use-case-4: to find all employees whose job titles are Sales Rep and sorting by reportsto and firstname */
select firstName,lastName,reportsTo,jobTitle from employees
where jobTitle='sales rep'
order by reportsto,firstname;
/* use-case-5: to find employees whose job titles are Sales Rep and office codes are 2*/
select firstName,lastName,officeCode,jobTitle from employees
where jobTitle='sales rep'
and officeCode='2';
/* use-case-6:  finds employees who are located in offices whose office code is from 1 to 3 */
select firstName,lastName,officeCode,jobTitle from employees
where officeCode between 1 and 3;
/* use-case-7 : finds the employees whose last names end with the string 'son' */
/* In like operator to form a pattern, you use the % and _ wildcards. */
/* The % wildcard matches any string of zero or more characters while the _ wildcard matches any single character. */
select firstname,lastname from employees
where lastname like '%son';
/* use-case-8: to find employees who are located in the offices with the codes 2, 4, and 6*/
select firstname,lastname,officecode from employees
where officecode in (2,4,6)
order by officeCode;
/* use-case-9: to get the rows with the values in the reportsTo column are NULL */
select firstname,lastname,reportsto from employees
where reportsTo is null;


/* Finding unique values in diferent columns */
/* query evaluation : from > where > distinct > select > order by */
/* use-case-10 : find unique lastnames from employee table */
select distinct lastname from employees 
order by lastname;
/* use-case-11 : find unique officecode and then unique jobtitles in each officecode */
select distinct officecode from employees;
select distinct officecode,jobtitle from employees
order by officecode, jobTitle;
/* use-case-12 : find if there is any duplicate emails - comparing no. of unique emails with no. of employees - both are 23*/
select distinct count(email) from employees;
select count(*) from employees;


/* query evaluation : from > where > distinct > select > order by > limit */
/* use-case-13 : to get the names of 5 employees having highest salary */
select firstname,lastname,jobtitle,officecode,salary from employees
order by salary desc
limit 5;




