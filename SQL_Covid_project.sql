SELECT [location], [date], total_cases, new_cases, total_cases, population
from Covid_Project..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if someone contract covid in india
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Covid_Project..CovidDeaths
where location like 'india'
order by 1,2

-- Looking at total Cases vs Population
-- Shows what percentage of population got Covid
SELECT [location], [date], total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
from Covid_Project..CovidDeaths
where location like 'india'
order by 1,2

-- Looking at countries with highest infection rate compared to population

SELECT [location], population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM Covid_Project..CovidDeaths
GROUP BY [location], population
ORDER BY PercentPopulationInfected DESC

-- Looking at Countries with highest death count per population

SELECT [location], MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covid_Project..CovidDeaths
WHERE continent is not NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- Looking at continent with highest death count per population

SELECT [location], MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covid_Project..CovidDeaths
WHERE continent is NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- 2nd method for looking at highest death count per population less accurate

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Covid_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Numbers 

-- Global total_cases, total_deaths, deathPercentage per day

SELECT date, SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM Covid_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1,2


-- Looking at total population vs vaccinations

SELECT dea.continent, dea.[location], dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS numeric)) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) as RollingPeopleVaccinated
FROM Covid_Project..CovidDeaths dea
JOIN Covid_Project..CovidVaccinations vac
ON dea.[location] = vac.[location]
and dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL -- AND dea.location like 'india'
ORDER BY 2,3


WITH PopvsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.[location], dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS numeric)) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) as RollingPeopleVaccinated
FROM Covid_Project..CovidDeaths dea
    JOIN Covid_Project..CovidVaccinations vac
    ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL -- AND dea.location like 'india'
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- Temp Table
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccination NUMERIC
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.[location], dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS numeric)) 
    OVER (PARTITION BY dea.[location] 
    ORDER BY dea.[location], dea.[date]) as RollingPeopleVaccinated
FROM Covid_Project..CovidDeaths dea
    JOIN Covid_Project..CovidVaccinations vac
    ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
-- WHERE dea.continent IS NOT NULL -- AND dea.location like 'india'
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccination/population)*100
FROM #PercentPopulationVaccinated


-- Creating View for later visualization

CREATE VIEW PercentPopulationVaccinated
as
SELECT dea.continent, dea.[location], dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS numeric)) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) as RollingPeopleVaccinated
FROM Covid_Project..CovidDeaths dea
JOIN Covid_Project..CovidVaccinations vac
ON dea.[location] = vac.[location]
and dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL -- AND dea.location like 'india'
-- ORDER BY 2,3
