
/* cleaning Data in SQL Queries */


Select * FROM master.dbo.NashvilleHousing;



-- Standardize Date Format 

Select SaleDateConvert, CONVERT(Date, SaleDate)
FROM master.dbo.NashvilleHousing

Update NashvilleHousing 
SET saledate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConvert Date;

Update NashvilleHousing 
SET SaleDateConvert = CONVERT(Date, SaleDate)


--------------------------------------------------------------------------------------------------------------------------

--Populate property Address Data

Select * 
FROM master.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM master.dbo.NashvilleHousing a
JOIN master.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM master.dbo.NashvilleHousing a
JOIN master.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null

------------------------------------------------------------------------------------------------
--Breaking Out Address into Individual Columns(Address, City, State)


Select PropertyAddress
FROM master.dbo.NashvilleHousing
--WHERE PropertyAddress is null
--ORDER BY ParcelID

SELECT
SUBSTRING(PropertyAddress, -1, CHARINDEX(',', PropertyAddress)) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address

FROM master.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(225);

Update NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(225);

Update NashvilleHousing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 


-------------------------------------------------------------------------------------------------------

--UPDATING OWNER ADDRESS

Select OwnerAddress FROM master.dbo.NashvilleHousing

Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM master.dbo.NashvilleHousing




ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(225);

Update NashvilleHousing 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE NashvilleHousing
Add  OwnerSplitCity Nvarchar(225);

Update NashvilleHousing 
SET  OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE NashvilleHousing
Add  OwnerSplitState Nvarchar(225);

Update NashvilleHousing 
SET  OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


----------------------------------------------------------------------------------------------------

---Change Y and N to Yes and No in "Sold as Vacant" Field

Select distinct(SoldAsVacant),Count(SoldAsVacant)
FROM master.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

Select SoldAsVacant,
	CASE when SoldAsVacant = 'Y' THEN 'YES'
		 when SoldAsVacant = 'N' THEN 'NO'
		 ELSE SoldAsVacant
		 END
FROM master.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 	CASE when SoldAsVacant = 'Y' THEN 'YES'
		 when SoldAsVacant = 'N' THEN 'NO'
		 ELSE SoldAsVacant
		 END;


-----------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM master.dbo.NashvilleHousing 
)

Select *  
FROM RowNumCTE 
where row_num > 1
order by PropertyAddress


--------------------------------------------------------------------------------------------------------------

--Delete unused columns

Select *
FROM master.dbo.NashvilleHousing

ALTER TABLE master.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate