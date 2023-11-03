SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    coviddeaths;
    
-- LOOKING AT TOTAL CASES vs TOTAL Deaaths
-- shows the likelihood of dying from contracting COVID
SELECT 
    location,
    date,
    total_cases,
    total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM
  coviddeaths
WHERE location LIKE '%kingdom%';

-- TOTAL CASES VS POPULATION-- 
SELECT 
    location,
    date,
    population,
    total_cases,
	(total_cases/population)*100 AS PercentPopulationInfected
FROM
  coviddeaths
 WHERE contintent IS NOT NULL;   
-- WHERE location LIKE '%states%'

-- COUNTRIES WITH HIGHEST INFECTION RATE compared to Population
 SELECT 
    location,
    population,
    MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM
  coviddeaths
WHERE contintent IS NOT NULL  
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;  

-- SHOWING THE COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION

SELECT Location, MAX(CAST(Total_deaths AS SIGNED)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
AND Location NOT IN ('Europe', 'North America', 'European Union', 'South America', 'Africa')
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- CONTINENT BREAKDOWN
SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL AND continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- CONTINENTS WITH HIGHEST DEATH COUNTS
SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL AND continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
Select SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS SIGNED)) AS total_deaths, SUM(cast(new_deaths AS SIGNED))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidDeaths
where continent is not null;
-- --Group By date

-- TOTAL POPUPLATION VS VACCINATIONS
-- --Shows Percentage of Population that has recieved at least one Covid Vaccine 


-- Calculate the rolling sum in a subquery
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;


-- USING CTE
WITH popvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- --, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3

)
SELECT *, (RollingPeopleVaccinated/population) * 100 FROM popvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated;

CREATE Table PercentPopulationVaccinated
(
Continent CHAR(255),
Location CHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%d/%m/%Y'), dea.population, vac.new_vaccinations,
    SUM(CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND STR_TO_DATE(dea.date, '%d/%m/%Y') = VAC.DATE
WHERE vac.new_vaccinations IS NOT NULL
AND vac.new_vaccinations != '';

SELECT *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;


Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- --, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
