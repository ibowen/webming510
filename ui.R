library(shiny)
library(leaflet)
library(DT)

# Choices for drop-downs
vars <- c(
  "Monthly Premium" = "mnthly_prm",
  "Annual Deductible" = "ann_ddctbl",
  "Average Household Income(,000$)" = "average_income",
  "Average Citizens per Physician" = "average_physician",
  "Unemployment Rate(%)" = "unemployment_rate",
  "Physician Specialties" = "spec_count",
  "Star Rating" = "Star_Rating_Current"
)


shinyUI(navbarPage("Durg and Health Plan Test Panel", id="nav",
                   tabPanel("Prediction Panel", 
                            fluidPage(
                                # Application title
                                #titlePanel("Preidictors"),
                                # Siderbar Input
                                sidebarLayout(
                                    sidebarPanel(
                                        # Select State and Contract
                                        selectInput(inputId = 'state', label   = 'Choose State:', choices = "AL"),
                                        #selectInput(inputId = 'contract_id', label   = 'Choose Contract:', choices = ""),
                                        
                                        h3('Internal Predictors'),
                                        sliderInput('tier', 'Tier Number', min = 2, max = 10, step = 1, value = 5),
                                        sliderInput('premium', 'Monthy Premium($)', min = 0, max = 100, step = 1, value = 20),
                                        sliderInput('deductible', 'Annualy Deductible($)', min = 0, max = 500, step = 10, value = 100),
                                        sliderInput('copayment', 'Maximium Copayment Rate(%)', min = 0, max = 100, step = 1, value = 20),
                                        sliderInput('coinsurance', 'Maximium Coinsurance Rate(%)', min = 0, max = 50, step = 1, value = 25),
                                        submitButton("submit")
                                    ),
                                    
                                    mainPanel(
                                        h1('Drug and Health Plan Design Panel'),
                                        helpText("This application is for predicting the customer ratings for the drug and Health Plan"),
                                        br(),
                                        
                                        DT::dataTableOutput('pred_list')
                                        
                                    )
                                )
                            )
                   ),
    tabPanel("Interactive Map",
        div(class="outer",
            tags$head(
              # Include our custom CSS
              includeCSS("styles.css"),
              includeScript("gomap.js")
            ),
            leafletOutput("map", width="100%", height="100%"),

            # Shiny versions prior to 0.11 should use class="modal" instead.
            absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                          draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                          width = 330, height = "auto",

                          h2("ZIP Explorer"),

                          selectInput("color", "Group By", vars),
                          submitButton("submit")
                          )
            ),
            tags$div(id="cite",
                     'Data compiled for ', tags$em('Coming Apart: The Medicare Data, 2014'), ' By 510_Team_2'
            )
    )
))