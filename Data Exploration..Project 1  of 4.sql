use PortfolioProject

select * from PortfolioProject..CovidDeaths$ with (nolock)
where continent is not null
order by 3, 4


select * from PortfolioProject..CovidVaccinations$


select location, date, total_cases, total_deaths, (total_deaths/total_cases) 
from PortfolioProject..CovidDeaths$ with (nolock)
order by 1,2



-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
select
	location,
	date,
	total_cases,
	total_deaths,
	CASE	
		WHEN TRY_CAST(total_cases as decimal(18, 2)) = 0 then null -- Handle divide by zero
		else TRY_CAST(total_deaths as decimal(18, 2)) / TRY_CAST(total_cases as decimal(18, 2)) * 100 
	    End as DeathPercentage
From 
	PortfolioProject..CovidDeaths$ with (nolock)
	where location = 'South Africa'
order by 
	location,
	date


	-- Total Cases vs Population
	-- Shows what percentage of population got Covid

	select
	location,
	date,
	population,
	total_cases,
	CASE	
		WHEN TRY_CAST(total_cases as decimal(18, 2)) = 0 then null -- Handle divide by zero
		else TRY_CAST(population as decimal(18, 2)) / TRY_CAST(total_cases as decimal(18, 2)) * 100 end as PercentPopulationInfected  
From 
	PortfolioProject..CovidDeaths$ with (nolock)
	where location = 'South Africa'
order by 
	location,
	date



	--Looking at countries with highest infection rate compared to Population

	select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population)) * 100 as PercentPopulationInfected
	from PortfolioProject.dbo.CovidDeaths$
	--where location = 'South Africa'
	group by location, population
	order by PercentPopulationInfected desc


	-- Showing countries with the highest death count per population

	select location, MAX(cast(total_deaths as int)) as TotalDeathCount
	from PortfolioProject.dbo.CovidDeaths$
	where continent is not null
	--where location = 'South Africa'
	group by location
	order by TotalDeathCount desc


	-- BREAKING DOWN BY CONTINENT


	select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
	from PortfolioProject.dbo.CovidDeaths$
	where continent is not null
	--where location = 'South Africa'
	group by continent
	order by TotalDeathCount desc


	-- Showing continents with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc




-- Global Numbers

select date, SUM(new_cases) as TotalCases,
			SUM(cast(new_deaths as int)) as TotalDeaths,
			(SUM(cast(new_deaths as int)) * 1.0 / nullif(SUM(new_cases), 0)) * 100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths$ with (nolock)
where continent is not null 
group by date
order by date



-- Looking at total population vs vaccinations

select 
dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS total_vaccinations

	from PortfolioProject.dbo.CovidDeaths$ Dea 
	join PortfolioProject.dbo.CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
		where dea.continent is not null 
		--and vac.new_vaccinations is not null and total_vaccinations is not null
		order by 2,3



-- USING CTE

With PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations)

as 
(
select 
dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS total_vaccinations

	from PortfolioProject.dbo.CovidDeaths$ Dea 
	join PortfolioProject.dbo.CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
		where dea.continent is not null 
		and vac.new_vaccinations is not null 
		--order by 2,3
		)

		SELECT *, (total_vaccinations / population) * 100  FROM PopvsVac 




-- Using a Temp Table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated(

continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
total_vaccinations numeric)

insert into #PercentPopulationVaccinated
select 
dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS total_vaccinations

	from PortfolioProject.dbo.CovidDeaths$ Dea 
	join PortfolioProject.dbo.CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
		--where dea.continent is not null 
		--and vac.new_vaccinations is not null 
		--order by 2,3

SELECT *, (total_vaccinations / population) * 100  FROM #PercentPopulationVaccinated 
	

-- Creating a view to store data for visulaizations

create view PercentPopulationVaccinated as

select 
dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS total_vaccinations

	from PortfolioProject.dbo.CovidDeaths$ Dea 
	join PortfolioProject.dbo.CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
		where dea.continent is not null  
		--order by 2,3

select * from PercentPopulationVaccinated