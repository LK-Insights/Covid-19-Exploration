/* Covid 19 Data Exploration  
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
FROM PortfolioProject..CovidDeaths
Where continent is not null 
Order by 3,4

--Selecting data to explore
Select location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Where continent is not null 
Order by 1,2


--Total Cases vs Total Deaths: Estimating COVID-19 Fatality Risk in Your Country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
Where location like '%states%'
and continent is not null 
Order by 1,2

--Total Cases vs Population: COVID-19 Infection Rate by percentage
Select location, date, population, (total_cases/population)*100 AS PercentPopInfected
FROM PortfolioProject.dbo.CovidDeaths
-- Where location like '%states%'
Where continent is not NULL
Order by 1,2

-- Countries with Hightest Infestion Rate compared to population
Select location, population, MAX(total_cases) HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopInfected
FROM PortfolioProject.dbo.CovidDeaths
-- Where location like '%states%'
Where continent is not NULL
Group by location, population
Order by PercentPopInfected Desc


--Countries with the Highest Fatality count per Population 
Select location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
-- Where location like '%states%'
Where continent is NULL
Group by location
Order by TotalDeathCount Desc


--*** BREAKING THINGS DOWN BY CONTINENT ***

--Continent with the Highest Fatality count per Population
Select continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
Where continent is not NULL
Group by continent
Order by TotalDeathCount Desc

--GLOBAL NUMBERS per Day 
SELECT date,  
    SUM(CAST(new_cases AS int)) AS Total_Cases, 
    SUM(CAST(new_deaths AS int)) AS Total_Deaths,
    SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float)) * 100 AS DeathsPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, Total_Cases


--Total Global Numbers of Deaths
SELECT  
    SUM(CAST(new_cases AS int)) AS Total_Cases, 
    SUM(CAST(new_deaths AS int)) AS Total_Deaths,
    (SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float)) * 100) AS DeathsPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY Total_Cases


--Total Population vs. Vaccinations (Percentage with At Least One Dose)
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccinations Vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3


--Using CTE to perform Calculation on Partition By in previous query with Rolling Total
with PopvsVac(continent, location, date, population, New_vaccinations, RollingPeopleVac)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccinations Vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
)
Select *, Convert(Float, RollingPeopleVac) / Convert(Float, population) *100 AS RollPercentPopVac
FROM PopvsVac


-- Temp Table #PercentPopVac

Drop Table if exists #PercentPopVac

Create table #PercentPopVac
(continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPopVac numeric
)
Insert into #PercentPopVac
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccinations Vac
	ON dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null 
Select *, (RollingPopVac/Population)*100
FROM #PercentPopVac


-- Creating Views to store data for later visualization
Create view PercentPopVac as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVac
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccinations Vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 

--Checking View
Select *
FROM PercentPopVac