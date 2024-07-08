--Select *
--From PortfolioProject..CovidDeaths
--order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

--Total cases vs total deaths (lethality rate)
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPerc
From PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
Group By date
order by 1,2

--Total population vs vaccinations
Select dea.continent, dea.location, dea.date, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVacCount 
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
order by 2,3

--Using CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVacCount)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVacCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
--order by 2,3
)
Select *, (RollingVacCount/Population)*100 as PercVac
From PopvsVac

--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Vaccinated vs Infected
Select dea.continent, dea.location, dea.date,
SUM(cast(vac.new_vaccinations AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVacCount,
SUM(cast(dea.new_cases AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingInfCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.location = 'United States'

WITH VacVsInf (Continent, Location, Date, Population, RollingVacCount, RollingInfCount)
AS
(
Select dea.continent, dea.location, dea.date, dea.population,
SUM(cast(vac.new_vaccinations AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVacCount,
SUM(cast(dea.new_cases AS int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingInfCount
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
)
Select location, date, (RollingVacCount/Population)*100 as PercVac, (RollingInfCount/Population)*100 as PercInf
From VacVsInf
Where Location = 'United States'


With bins AS (
Select generate_series('2020-01-22 00:00:00.000','2021-04-30 00:00:00.000', '3 months'::interval) as lower,
