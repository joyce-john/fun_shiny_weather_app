# libraries
library(httr)
library(jsonlite)
library(data.table)
library(lubridate)
library(readr)
library(ggplot2)
library(ggiraph)
library(DT)

# enable state bookmarking via parameters in URL
enableBookmarking(store = "url")

################################################################################


## -----> loading required local data


# API key for weather data
API_KEY <- readLines('data/api_key.txt')

# load city names and coordinates, generate new column "city,countrycode"
cities <- fread("data/worldcities.csv", encoding = "UTF-8")
cities[, unique_code := paste0(city_ascii,", ",iso2)]


################################################################################


## -----> for getting "today's weather" data


# function to get current weather
# takes city name as input
# defaults to Budapest
get_current_weather <- function(location = "Budapest, HU", unit_type = "metric"){

  response <- GET(
    url = "http://api.openweathermap.org/data/2.5/weather",
    query = list(
      q = location,
      units = unit_type,
      APPID = API_KEY
    ))

  response_content <- content(response)

  current_weather <-
    data.table(general_description = response_content$weather[[1]]$main,
               specific_description = response_content$weather[[1]]$description,
               temperature_current = response_content$main$temp,
               temperature_feels_like = response_content$main$feels_like,
               temperature_min = response_content$main$temp_min,
               temperature_max = response_content$main$temp_max,
               humidity = response_content$main$humidity,
               visibility = response_content$main$visibility,
               wind_speed = response_content$wind$speed,
               rain_in_next_hour = response_content$rain$`1h`)

  return(current_weather)

}


################################################################################


## -----> for getting weekdays from integer values from data.table::wday()


# takes an integer and returns a weekday name
get_weekday <- function(int){

  weekday_names <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday")

  return(weekday_names[int])

}

################################################################################


## -----> for getting "weekly forecast" data


# gets a weekly forecast
# takes longitude and latitude as inputs
# defaults to Budapest coordinates, metric units
get_forecast <- function(longitude = "19.08333", latitude = "47.5", unit_type = "metric"){

  # query API
  response <- GET(
    url = "https://api.openweathermap.org/data/2.5/onecall",
    query = list(
      lat = latitude,
      lon = longitude,
      units = unit_type,
      exclude = "hourly,minutely",
      APPID = API_KEY
    ))

  # get content of response
  response_content <- content(response)

  # function for parsing response - it's easier to store it here rather than globally
  # takes i as an input, where i is the position of one observation in the nested list of response$daily
  get_one_day_of_data_from_weekly_forecast <- function(i){

    # get datetime
    date <-
      lubridate::as_date(as.POSIXct(response_content$daily[[i]]$dt, origin="1970-01-01", tz = response_content$timezone))

    # get datetime and convert to string of day
    day_of_week <-
      get_weekday(data.table::wday(date))

    # general_description: sunny, rainy, etc
    general_description <-
      response_content$daily[[i]]$weather[[1]]$main

    # specific_description: "light rain", "a bit cloudy", etc.
    specific_description <-
      response_content$daily[[i]]$weather[[1]]$description

    # temperature during the day
    temp_daytime <-
      response_content$daily[[i]]$temp$day

    # minimum temperature
    temp_min <-
      response_content$daily[[i]]$temp$min

    # maximum temperature
    temp_max <-
      response_content$daily[[i]]$temp$max

    # list to return
    day_list <- list(date = date,
                     day_of_week = day_of_week,
                     general_description = general_description,
                     specific_description = specific_description,
                     temp_daytime = temp_daytime,
                     temp_min = temp_min,
                     temp_max = temp_max)

    return(day_list)

  }

  # call the response parsing function for all 8 days (today + one week)
  weekly_df <- rbindlist(lapply(1:8, get_one_day_of_data_from_weekly_forecast))

  # create helper column for plotting - this generalizes weather conditions
  weekly_df[, color_code := sapply(general_description, evaluate_conditions)]

  return(weekly_df)

}


################################################################################


## -----> for generalizing weather conditions into a small number of categories to be color-coded on plot


# evaluates conditions and returns an appropriate color for plotting
evaluate_conditions <- function(general_description){

  if(general_description %in% c("Rain", "Drizzle", "Snow", "Thunderstorm")){
    evaluation <- "precipitation"
  } else if (general_description %in% c("Clouds", "Haze", "Mist")){
    evaluation <- "not_clear"
  } else if (general_description %in% c("Smoke", "Dust", "Fog", "Sand", "Ash", "Squall", "Tornado")){
    evaluation <- "dangerous"
  } else{
    evaluation <- "clear"
  }

  return(evaluation)

}


################################################################################


## -----> color-coding values for ggplot. weather condition = named ggplot color


# colors for different weather conditions when plotting
condition_colors <- c("precipitation" = "dodgerblue3",
                      "not_clear" = "lightsteelblue4",
                      "dangerous" = "orangered3",
                      "clear" = "gold1")


################################################################################


# -----> generating the weekly forecast plot


# make the forecast plot from a dataframe returned by the get_forecast() function
make_weekly_forecast_plot <- function(forecast_weather){
  
  # create plot
  weekly_forecast_plot <-
  ggplot(data = forecast_weather, aes(x = as.Date(date))) +
    geom_line_interactive(aes(y = temp_daytime), size = 1.25) +
    geom_point_interactive(aes(y = temp_daytime,
                               color = color_code,
                               tooltip = paste0("Temperature: ", round(temp_daytime, 0), "&deg;", #render degree symbol in picky HTML engines
                                                "\n",
                                                "Conditions: ", specific_description)), size = 7) +
    labs(x = "", y = "") +
    scale_x_date(date_breaks = "1 day", date_labels = "%A") +
    theme_light() +
    scale_color_manual_interactive(values = condition_colors) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text = element_text(size = 11, face = "bold"),
          legend.position = "none")

  # return plot
  return(weekly_forecast_plot)
  
  
  
}
