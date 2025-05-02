/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Check Import files
select *
From Projects..CovidDeaths
order by 3,4

SELECT *
FROM Projects..CovidVaccinations
order by 3,4

-- Selecitng data to explore
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Projects..CovidDeaths
Where continent is not null
order by 1,2

Select *
From Projects..CovidDeaths
Where continent is not null 
order by 3,4

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your county
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_pct
FROM Projects..CovidDeaths
WHERE location like '%states%' 
order by 1,2

-- Total Cases vs Population
-- Shows percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as pctPopulationInfected
From Projects..CovidDeaths
--Where location like '%states%'
Where continent is not null
order by 1,2


--Countries with Highest Infestion Rate compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as pctPopulationInfected
From Projects..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by location, population
order by pctPopulationInfected desc


--Countries with the highest Death count per population
Select location, MAX(CAST(total_deaths as int)) as TtlDeathCount
From Projects..CovidDeaths
Where continent is not null
Group by location, population
order by TtlDeathCount desc


---- BREAK DOWN BY CONTINENT
--Continent with the highest Death count per population
Select continent, MAX(CAST(total_deaths as int)) as TtlDeathCount
From Projects..CovidDeaths
Where continent is not null
Group by continent
order by TtlDeathCount desc


-- GLOBAL NUMBERS
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPct
From Projects..CovidDeaths
--Where location like '%states%'
where continent is not null 
Group by date
order by 1,2

-- Global Total numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPct
From Projects..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group by date
order by 1,2

-- Join CovidDeaths table with CovidVaccination table
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CAST(Vac.new_vaccinations as int)) over (Partition by Dea.location Order by Dea.location, Dea.date) RollingPeopleVacinated
FROM Projects..CovidDeaths Dea
JOIN Projects..CovidVaccinations Vac
	On Dea.location =Vac.location
	and Dea.date = Vac.date
Where Dea.continent is not null
Order by 2,3


-- CTE - temporary result - Using CTE to perform running total calculation on Partition By in previous query
-- and Prepare a subset of CovidDeaths and CovidVaccinations.

With PopvsVac (continent, location, date, population, new_Vaccinations, RollingPeopleVac)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVac
--, (RollingPeopleVac/population)*100
From Projects..CovidDeaths dea
Join Projects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVac/Population)*100
From PopvsVac


-- TEMP Table for performing Calculation on 'Partition By' using previous query

Drop Table if exists #PercentPopVac

Create Table #PercentPopVac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVac numeric
)

Insert into #PercentPopVac
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVac
--, (RollingPeopleVac/population)*100
From Projects..CovidDeaths dea
Join Projects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
Select *, (RollingPeopleVac/Population)*100
From #PercentPopVac


-- Creating View to store data for later visualizations
Create View PercentPopVac as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVac
--, (RollingPeopleVac/population)*100
From Projects..CovidDeaths dea
Join Projects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVac/Population)*100
From #PercentPopVac


--Checking view
SELECT *
FROM PercentPopVac
