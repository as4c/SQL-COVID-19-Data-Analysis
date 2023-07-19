
Select * 
From MyDb..CovidDeath
order by 3, 4;

Select * 
From MyDb..covidVaccinationDb
order by 3, 4;

-- Select Data that i will use

Select Location , date, total_cases, new_cases, total_deaths, population
From MyDb..CovidDeath
order by 1, 2;

-- Now Looking at Total Cases vs Total Deaths
ALTER TABLE MyDb..CovidDeath
ALTER COLUMN total_deaths INT;

ALTER TABLE MyDb..CovidDeath
ALTER COLUMN total_cases INT;


SELECT
    Location,
    Date,
    total_cases,
    total_deaths,
    CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT )* 100 AS death_rate_percentage
FROM
    MyDb..CovidDeath
WHERE Location like '%india%'
ORDER BY
    Location,
    Date;


-- Looking at Total Cases vs Population => it shows what percentage of population got covid
SELECT
    Location,
    Date,
    total_cases,
    population,
    CAST(total_cases AS FLOAT) / CAST(population AS FLOAT )* 100 AS covid_infection_rate
FROM
    MyDb..CovidDeath
WHERE Location like '%india%'
ORDER BY
    Location,
    Date;
	
-- Now Looking Countries with Highest Infection Rate Compared to Population

SELECT Location, Population,
MAX(total_cases) AS HighestInfectionCount, 
MAX((CAST(total_cases AS FLOAT) / CAST(Population AS FLOAT ))* 100) AS PercentPopulationInfected
FROM MyDb..CovidDeath
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;



-- Countries with Highest Death Count per Population

Select Location, 
MAX(CAST(Total_deaths AS INT )) AS TotalDeathCount
FROM MyDb..CovidDeath
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;



-- CONTINENT WITH HIGHEST DEATH COUNT

SELECT continent,
MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM MyDb..CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount DESC;



-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths AS INT)) AS total_deaths ,
SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM MyDb..CovidDeath
WHERE continent IS NOT NULL AND new_cases IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT,vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated 
--,(RollingPeopleVaccinated/population)*100
FROM MyDb..CovidDeath dea
JOIN MyDb..covidVaccinationDb vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3



-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated 
--,(RollingPeopleVaccinated/population)*100
FROM MyDb..CovidDeath dea
JOIN MyDb..covidVaccinationDb vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM MyDb..CovidDeath dea
JOIN MyDb..covidVaccinationDb vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--DROP Table if exists #PercentPopulationVaccinated
--Create Table #PercentPopulationVaccinated
--(
--Continent nvarchar(255),
--Location nvarchar(255),
--Date datetime,
--Population numeric,
--New_vaccinations numeric,
--RollingPeopleVaccinated numeric
--)

--Insert into #PercentPopulationVaccinated
--Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
----, (RollingPeopleVaccinated/population)*100
--From MyDb..CovidDeath dea
--Join MyDb..covidVaccinationDb vac
--	On dea.location = vac.location
--	and dea.date = vac.date
----where dea.continent is not null 
----order by 2,3

--Select *, (RollingPeopleVaccinated/Population)*100
--From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM MyDb..CovidDeath dea
JOIN MyDb..covidVaccinationDb vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;