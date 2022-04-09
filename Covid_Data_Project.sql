-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country

SELECT location, date, (total_cases), total_deaths, ((total_deaths/total_cases)*100) AS 'Death_Rate' 
FROM cv_deaths 
WHERE location = 'United States'
ORDER BY date

-- Total Cases vs Population
-- Shows what percentage of population infected

SELECT location, population, MAX(total_cases) AS 'total_cases', MAX((total_cases/population)*100) AS 'Infection_Rate' 
FROM cv_deaths 
GROUP BY location, population
ORDER BY 'Infection_Rate' DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) AS 'Death_Count'
FROM cv_deaths 
WHERE continent is NOT NULL
GROUP BY location
ORDER BY 'Death_Count' DESC

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS 'Death_Count'
FROM cv_deaths 
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY 'Death_Count' DESC

-- GLOBAL NUMBERS

SELECT SUM(cast(new_cases as int)) AS 'Global_Cases', SUM(cast(new_deaths as int)) AS 'Global_Deaths', 
(SUM(cast(new_deaths as int))/ SUM(new_cases)*100) AS 'Global_Death_Rate'
FROM cv_deaths
WHERE continent is NOT NULL
order by 1, 2

-- Vaccination Information

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'Total_Vaccinations' 
FROM cv_deaths dea
JOIN cv_vaccinations vac
ON
dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH popvac(Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'Total_Vaccinations' 
FROM cv_deaths dea
JOIN cv_vaccinations vac
ON
dea.location = vac.location and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ((Total_Vaccinations/population)*100) AS 'Vaccination_Percentage' FROM popvac

-- Using Temp Table to perform Calculation on Partition By in previous query

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
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From cv_deaths dea
Join cv_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From cv_deaths dea
Join cv_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
