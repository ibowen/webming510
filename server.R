library(shiny)
library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(C50)
library(DT)

# file path for the final data set
filepath <- "./data/final_data_v3.csv"
# read files
if(!exists(filepath)) {
    data <- read.csv(file = filepath)
    # remove neutral 4 points, and change the label into 1 and 0
    data_rm4 <- data[data$Star_Rating_Current != 4, ]
    # transfer the label into binary value
    data_rm4$sentiment <- ifelse(data_rm4$Star_Rating_Current > 4,1,0)
    # transfer sentiment to factor variables
    data_rm4$sentiment <- factor(data_rm4$sentiment, levels = c(0,1), labels = c('Bad','Good'))
    # subset the needed columns for modeling
    colnames <- c('experience', 'spec_count', 'unemployment_rate', 'average_income', 'average_physician', 'tier_label', 'mnthly_prm', 'ann_ddctbl', 'copay_max', 'coin_max', 'sentiment')
    data_rm4 <- data_rm4[, colnames]
    
    # Logistic Regression Modeling
    logsitic_regression_model = glm(formula = sentiment ~ ., family = binomial(link = 'logit'), data = data_rm4)
    
    # subset the state list
    state_list <- as.list(rownames(table(data$state)))
    # subset the contract list
    contract_list <- as.list(rownames(table(data$contract_id)))
    
    # colnames to show
    colnames_show <- c('Rating', 'State', 'County', 'Zip', 'Experience(years)', 'Physician Speciaties', 'Unemployment(%)', 'Avg Income(,000$)', 
                       'Citizens/Physician', 'Tiers', 'Monthy Premium($)', 'Annualy Deductible($)', 'Max Copayment(%)', 'Max Coinsurance(%)')
}

# Leaflet bindings are a bit slow; for now we'll just sample to compensate
set.seed(100)
# By ordering by centile, we ensure that the (comparatively rare) SuperZIPs
# will be drawn last and thus be easier to see
# data <- data[order(data$polulation),]

shinyServer(function(input, output, session) {
  
  ## Interactive Map ###########################################

    # Create the map
    output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = -93.85, lat = 37.45, zoom = 4)
    })

    # A reactive expression that returns the set of zips that are
    # in bounds right now
    zipsInBounds <- reactive({
        if (is.null(input$map_bounds))
          return(data[FALSE,])
        bounds <- input$map_bounds
        latRng <- range(bounds$north, bounds$south)
        lngRng <- range(bounds$east, bounds$west)

        subset(data,
               latitude >= latRng[1] & latitude <= latRng[2] &
                 longitude >= lngRng[1] & longitude <= lngRng[2])
    })


    # This observer is responsible for maintaining the circles and legend,
    # according to the variables the user has chosen to map to color and size.
    observe({
        colorBy <- input$color

    if (colorBy == "average_physician") {
        #Color and palette are treated specially in the "superzip" case, because
        #the values are categorical instead of continuous.
        colorData <- ifelse(data$average_physician <= 100, "0-100", ifelse(data$average_physician<=500, "100-500", ifelse(data$average_physician <= 1000, "500-1000", "1000+")))
        pal <- colorFactor("Spectral", colorData)
        radius <- data[[colorBy]]  / max(data[[colorBy]]) * 60000 
    } else {
      if(colorBy == "unemployment_rate") {
        colorData <- ifelse(data$unemployment_rate <= 2.5, "0%-2.5%", ifelse(data$unemployment_rate<=4.5, "2.5%-4.5%", ifelse(data$unemployment_rate <= 8.0, "4.5%-8%", "8%+")))
        pal <- colorFactor("Spectral", colorData)
        radius <- data[[colorBy]] / max(data[[colorBy]]) * 50000
      } else{
        if(colorBy == "average_income") {
          colorData <- ifelse(data$average_income <= 10, "0-10", ifelse(data$average_income<=25, "10-25", ifelse(data$unemployment_rate <= 50, "25-50", "50+")))
          pal <- colorFactor("Spectral", colorData)
          radius <- data[[colorBy]] / max(data[[colorBy]]) * 50000
        } else{
          colorData <- data[[colorBy]]
          pal <- colorBin("Spectral", colorData, 7, pretty = FALSE)
          radius <- data[[colorBy]] / max(data[[colorBy]]) * 20000
        }
      }
    }


    leafletProxy("map", data = data) %>%
      clearShapes() %>%
      addCircles(~longitude, ~latitude, radius=radius, layerId= ~zip_code,
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addLegend("bottomleft", pal=pal, values = colorData, title=colorBy,
                layerId="colorLegend")
    })

    # Show a popup at the given location
    showZipcodePopup <- function(zipcode, lat, lng) {
    selectedZip <- data[data$zip_code == zipcode,]
    content <- as.character(tagList(
      tags$h4("Monthly Premium($):", as.integer(selectedZip$mnthly_prm)),
      tags$strong(HTML(sprintf("%s", selectedZip$zip_code))),
      tags$br(),
      sprintf("Average Household Income(,000$): %s", dollar(selectedZip$average_income)),
      tags$br(),
      sprintf("Average Work Experience for Physicians: %s", as.integer(selectedZip$experience)),
      tags$br(),
      sprintf("Average Citizens per Physician: %s", selectedZip$average_physician)
    ))
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = zip_code)
    }

    # When map is clicked, show a popup with city info
    observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_shape_click
    if (is.null(event))
      return()

    isolate({
      showZipcodePopup(event$id, event$lat, event$lng)
    })
    })
  
    # Preidction Part #######################
    # External Predictors with Geographic Info
    data_external <- reactive({
        unique(data[data$state == input$state, c('state', 'county', 'zip_code', 'experience', 'spec_count', 'unemployment_rate', 'average_income', 'average_physician')])
    })
    # Internal Predictors
    data_internal <- reactive({
        data_internal <- c(input$tier, input$premium, input$deductible, input$copayment, input$coinsurance)
        t(replicate(nrow(data_external()), data_internal))
    })
    # Ratings
    data_rating <- reactive({
        data_external <- data_external()[, -c(1,2,3)]
        predictors <- cbind(data_external, data_internal())
        predictors$dummy <- 'dummy'
        colnames(predictors) <- colnames
        lr_pred <- predict(logsitic_regression_model, newdata = predictors, type = "response")
        #lr_rating <- paste("The Logistic Regression Probability: ", round(lr_pred, 2))
        ifelse(lr_pred > 0.5, 'Good', 'Bad')
    })
    
    # Final Data Sent back to client
    data_show <- reactive({
        data_show <- cbind(cbind(data_rating(), data_external()), data_internal())
        rownames(data_show) <- NULL
        data_show
    })
    
    output$pred_list <- DT::renderDataTable({
        DT::datatable(data_show(), colnames = colnames_show)
  })

  # fill states
  observe({
      updateSelectInput(session, "state", choices = state_list, selected = state_list[1])
  })
  
  # fill contract id
  observe({
      updateSelectInput(session, "contract_id", choices = contract_list, selected = contract_list[1])
  })
  
})

