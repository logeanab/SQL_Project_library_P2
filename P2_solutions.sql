-- SQL Project - Library Management System N2
SELECT * FROM books
WHERE isbn = '978-0-7432-7357-1'
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-7432-7357-1'
SELECT * FROM members;
SELECT * FROM return_status;

/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

--issued_status == members == books == return_status
-- filter books which is return
-- overdue > 30

SELECT CURRENT_DATE

SELECT 
	myt.issued_member_id,
	a.member_name,
	bk.book_title,
	myt.issued_id,
	--rs.return_date,
	CURRENT_DATE - myt.issued_date as over_dues_days
FROM issued_status as myt
JOIN
members as a
	ON a.member_id = myt.issued_member_id
JOIN 
books as bk
ON bk.isbn = myt.issued_book_isbn
LEFT JOIN
return_status as rs
ON rs.issued_id = myt.issued_id
WHERE 
	rs.return_date IS NULL
	AND 
	(CURRENT_DATE - myt.issued_date) > 30
ORDER BY 1

/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/
SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2'

SELECT * FROM books
WHERE isbn = '978-0-451-52994-2'

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM return_status
WHERE issued_id = 'IS130';

-- 
ALTER TABLE return_status
ADD COLUMN book_quality VARCHAR(50);

INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
VALUES 
('RS125', 'IS130', CURRENT_DATE, 'Good');
SELECT * FROM return_status
WHERE issued_id = 'IS130';

UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-451-52994-2';

-- Stored Procedures
CREATE OR REPLACE PROCEDURE add_return(p_return_id VARCHAR(20), p_issued_id VARCHAR(20), p_book_quality VARCHAR(50))
LANGUAGE plpgsql
AS $$
DECLARE
	v_isbn VARCHAR(20);
	v_book_name VARCHAR(55);
BEGIN
	--all your logic and code
	--inserting into return based on users input
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES 
	(p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO 
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;	

	RAISE NOTICE 'Thank you for returning the book: %', v_book_name;

END;
$$

CALL add_return records();

--Testing FUNCTIONS add_return
issued_id = IS135
ISBN = WHERE isbn = '978-0-7432-7357-1'

SELECT * FROM issued_status
WHERE issued_id = 'IS136'

SELECT * FROM return_status
WHERE issued_id = 'IS136'

SELECT * FROM books
WHERE isbn = '978-0-7432-7357-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-7432-7357-1'

SELECT * FROM return_status
WHERE issued_id = 'IS136';

CALL add_return('RS150', 'IS136', 'Good');

--Task 15: Branch Performance Report: Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
SELECT * FROM branch;

SELECT * FROM issued_status;

SELECT * FROM employees;

SELECT * FROM books;

SELECT * FROM return_status;

CREATE TABLE branch_reports
AS
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(myt.issued_id) as number_book_issued,
	COUNT(rs.return_id) as number_of_book_return,
	SUM(CAST(NULLIF(bk.rental_price, '') AS NUMERIC)) AS total_revenue
FROM issued_status as myt
JOIN 
employees as e
ON e.emp_id = myt.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = myt.issued_id
JOIN
books as bk
ON myt.issued_book_isbn = bk.isbn
GROUP BY 1, 2

/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 20 months.*/

CREATE TABLE active_members
AS
SELECT * FROM members	
WHERE member_id IN (SELECT 
						DISTINCT issued_member_id
					FROM issued_status
					WHERE 
						issued_date >= CURRENT_DATE - INTERVAL '20 month'
					)
;

SELECT * FROM active_members

/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/

SELECT 
	e.emp_name,
	b.*,
	COUNT(myt.issued_id) as no_book_issued
	
FROM issued_status as myt
JOIN
employees as e
ON e.emp_id = myt.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2

/*Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.
*/

--I SHOULD ANSWER THIS

/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

SELECT * FROM books;
SELECT * FROM issued_status;

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(50), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$
DECLARE
--all the variable
	v_status VARCHAR(10); 


BEGIN
--all the logic
	--checkingif the book is available
	SELECT 
		status 
		INTO
		v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN
	
	INSERT INTO issued_status(issued_id, issued_member_id , issued_date, issued_book_isbn, issued_emp_id)
	VALUES
	(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
	
	UPDATE books
		SET status = 'no'
	WHERE isbn = p_issued_book_isbn;
	
	RAISE NOTICE 'Book records added successfully for book isbn : %' , p_issued_book_isbn;
	
	ELSE 
		RAISE NOTICE 'Sorry to inform you the book you have reuqested is unavailable book isbn : %' , p_issued_book_isbn;
	END IF;

END;
$$	

SELECT * FROM books;
--"978-0-553-29698-2" -- yes
--"978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS145', 'C109','978-0-553-29698-2', 'E105' )
CALL issue_book('IS146', 'C109','978-0-375-41398-8', 'E105' )

/*Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines*/

--I SHOULD ANSWER THIS



