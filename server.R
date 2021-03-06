# libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)

# load helper functions, stored values from global.R
source("helper/global.R")

# server functions make some API calls, rely heavily on helpers from global.R
server <- function(input, output, session) {
  
  
  
  ### -----> STORE INPUT PARAMETERS IN URL <----- ###
  
  observe({
    # Trigger this observer every time an input changes
    reactiveValuesToList(input)
    session$doBookmark()
  })
  
  onBookmarked(function(url) {
    updateQueryString(url)
  })
  

  
  ### -----> TODAY'S WEATHER OUTPUT <----- ###
  
  updateSelectizeInput(session, 'curr_city', choices = cities$unique_code, selected = "Budapest, HU", server = TRUE)
  
  observeEvent(c(input$curr_city,input$curr_measurement), {
    
    curr_weather <- get_current_weather(location = input$curr_city, unit_type = input$curr_measurement)
    
    output$curr_temp <- renderInfoBox({infoBox(title = "Temperature", value = paste0(round(curr_weather$temperature_current,0), "°"), icon = icon('thermometer-half'))
    })
    
    output$curr_feel <- renderInfoBox({infoBox(title = "Feels like", value = paste0(round(curr_weather$temperature_feels_like, 0), "°"), icon = icon('hand-holding'))
    })
    
    output$curr_condition <- renderInfoBox({infoBox(title = "Condition", value = curr_weather$specific_description, icon = icon('globe'))
    })
    
    output$curr_image <- renderImage({
      list(
        src = paste0("www/",curr_weather$general_description,".jpg"),
        contentType = "image/jpg",
        height = 800, # session$clientData$output_myImage_height, #might work with tweaks
        width =  2000, # session$clientData$output_myImage_width, # might work with tweaks
        alt = "scientific_photo_of_weather")
      
      
    }, deleteFile = FALSE)
    
  })
  


  ### -----> FORECAST WEATHER OUTPUT <----- ###
  
  updateSelectizeInput(session, 'forecast_city', choices = cities$unique_code, selected = "Budapest, HU", server = TRUE)
  
  observeEvent(c(input$forecast_city,input$forecast_measurement), {
    
    # get weather forecast for selected city. if there is more than one city with the selected name, take the one with the largest population
    forecast_weather <-  get_forecast(longitude = cities[cities$unique_code == input$forecast_city][order(-population)][1]$lng,
                                      latitude = cities[cities$unique_code == input$forecast_city][order(-population)][1]$lat,
                                      unit_type = input$forecast_measurement)
    
    output$plot_forecast <- renderGirafe({
      girafe(ggobj = make_weekly_forecast_plot(forecast_weather))
    })
    
    # do some data.table column name manipulations for a nicer table
    output$forecast_table <- DT::renderDataTable({
      
      forecast_weather[,  .(Date = date, 
                            Day = day_of_week, 
                            Condition = specific_description,
                            Temp = temp_daytime,
                            High = temp_max,
                            Low = temp_min)]
      
    }, options = list(dom = 't')) # options to hide unneeded UI elements
    
    
  })

  
  ### -----> APP SURVEY PAGE <----- ###
  
  
  
  # listen for survey submit button
  observeEvent(input$submit_survey,{
    
    # reactive value for survey validity - all inputs must be TRUE for this value to be TRUE
    rv <- reactiveValues('valid' = input$q1 & input$q2 & input$q3)
    
    sendSweetAlert(session = session,
                   title = ifelse(rv$valid == TRUE, "Thank you.", "Error."),
                   text = ifelse(rv$valid == TRUE, "Your positive feedback is appreciated.", "One or more responses was invalid."),
                   type = ifelse(rv$valid == TRUE, "success", "error"))
    
    
  })
  
}
