# libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)

# load helper functions, stored values from global.R
source("helper/global.R")

# dashboard style UI
ui <- dashboardPage(
  
  skin = 'black',
  
  dashboardHeader(
    title = "Weather Forecast"
  ),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem('Today', tabName = 'today'),
      menuItem('Weekly Forecast', tabName = 'weekly_forecast'),
      menuItem('App Survey', tabName = 'survey'),
      menuItem('Attribution', tabName = 'attribution')
      
    )
  ),
  
  dashboardBody(
    
    # css to scale current weather image
    tags$head(tags$style(
      type="text/css",
      "#curr_image img {max-width: 100%; width: 100%; height: 100%}"
    )),
    
    tabItems(
      tabItem(tabName = 'today',
              
              fluidRow(
                
                # KPI-style info boxes of current temperature, temp feeling, description condition
                infoBoxOutput('curr_temp'),
                infoBoxOutput('curr_feel'),
                infoBoxOutput('curr_condition')

                
                
              ),
              
              fluidRow(
                
                box(width = 6,   
                
                # select city from list
                selectizeInput(
                  'curr_city', label = h3("Select city"),
                  choices = NULL
                )),
                
                box(width = 6,
                    
                    # select measurement system from radio buttons
                    radioButtons("curr_measurement", label = h3("Measurement system"),
                                 choices = list("imperial" = "imperial", "metric" = "metric"), 
                                 selected = "metric"))
                
              ),
              
              fluidRow(
                
                box(width = 12,
                    
                    # show image based on current condition
                    imageOutput("curr_image")
                )
              )
      ),
      
      tabItem(tabName = 'weekly_forecast',
              
              fluidRow(
                
                box(width = 6,    

                    # select city from list
                    selectizeInput(
                      'forecast_city', label = h3("Select city"),
                      choices = NULL
                    )
                    
                    ),
                
                box(width = 6,
                    
                    # select measurement system from radio buttons
                    radioButtons("forecast_measurement", label = h3("Measurement system"),
                                 choices = list("imperial" = "imperial", "metric" = "metric"), 
                                 selected = "metric"))
              ),
              
              box(width = 6,
                  
                  # plot of weather for coming week
                  girafeOutput('plot_forecast')
              ),
              
              box(width = 6,
                  
                  # table of weather details for dorks
                  DT::dataTableOutput('forecast_table'))
              
              
      ),
      
      tabItem(tabName = 'survey',
              
              h1("We value your feedback. Please take a minute to fill out our survey."),
              hr(),
              hr(),
              hr(),
              h2("Are you satisfied with the selection of cities on this app?"),
              switchInput(
                inputId = "q1",
                onLabel = "Yes",
                offLabel = "No",
                size = "large"),
              h2("In your opinion, are these forecasts accurate and reliable?"),
              switchInput(
                inputId = "q2",
                onLabel = "Yes",
                offLabel = "No",
                size = "large"),
              h2('Would you recommend this app to a friend?'),
              switchInput(
                inputId = "q3",
                onLabel = "Yes",
                offLabel = "No",
                size = "large"),
              hr(),
              hr(),
              actionBttn(
                inputId = "submit_survey",
                label = "Submit survey", 
                style = "material-flat",
                color = "danger"
              )
              
              
              
              
      ),
      
      tabItem(tabName = 'attribution',
              
              h1("Thanks to these organizations..."),
              h2(tags$a(href = "https://openweathermap.org/api","OpenWeatherMap")),
              h4("for their generous free-tier weather API"),
              h2(tags$a(href = "https://simplemaps.com", "SimpleMaps")),
              h4("for kindly licensing their handy list of city names with coordinates under CC 4.0")
              
      )
    )
  )
)

