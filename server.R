# libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)

# load helper functions, stored values from global.R
source("helper/global.R")

# server functions make some API calls, rely heavily on helpers from global.R
server <- function(input, output, session) {
  
  ### -----> TODAY'S WEATHER OUTPUT <----- ###
  
  output$curr_temp <- renderInfoBox({infoBox(title = "Temperature", value = paste0(get_current_weather(location = input$curr_city, unit_type = input$curr_measurement)$temperature_current, "°"), icon = icon('thermometer-half'))
  })
  
  output$curr_feel <- renderInfoBox({infoBox(title = "Feels like", value = paste0(round(get_current_weather(location = input$curr_city, unit_type = input$curr_measurement)$temperature_feels_like, 0), "°"), icon = icon('hand-holding'))
  })
  
  output$curr_condition <- renderInfoBox({infoBox(title = "Condition", value = get_current_weather(location = input$curr_city, unit_type = input$curr_measurement)$specific_description, icon = icon('globe'))
  })
  
  output$curr_image <- renderImage({
    list(
      src = paste0("www/",get_current_weather(location = input$curr_city)$general_description,".jpg"),
      contentType = "image/jpg",
      height = 400, # session$clientData$output_myImage_height, #might work with tweaks
      width =  1000, # session$clientData$output_myImage_width, # might work with tweaks
      alt = "scientific_photo_of_weather")
    
    
  }, deleteFile = FALSE)
  


  ### -----> FORECAST WEATHER OUTPUT <----- ###
  
  output$plot_forecast <- renderGirafe({
    girafe(ggobj = make_weekly_forecast_plot(input_forecast_city = input$forecast_city, input_forecast_measurement = input$forecast_measurement))
  })
  
  
  output$forecast_table <- renderDataTable({
    get_forecast(longitude = cities$lng[cities$unique_code == input$forecast_city],
                 latitude = cities$lat[cities$unique_code == input$forecast_city],
                 unit_type = input$forecast_measurement)[,  .(Date = date, 
                                                              Day = day_of_week, 
                                                              Condition = specific_description,
                                                              Temp = temp_daytime,
                                                              High = temp_max,
                                                              Low = temp_min)]
  }, options = list(dom = 't'))
  
  
  
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
