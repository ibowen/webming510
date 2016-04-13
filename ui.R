library(shiny)
shinyUI(pageWithSidebar(
    headerPanel("Predictor List"),
    sidebarPanel(
        sliderInput('experience', 'Average Work Experience(years)', min = 0, max = 40, step = 1, value = 10),
        sliderInput('unemployment', 'Unemployment Rate(%)', min = 0, max = 100, step = 1, value = 5),
        sliderInput('income', 'Average Income(,000$)', min = 0, max = 100000, step = 5, value = 30),
        sliderInput('physician', 'Average Citizens per Physician', min = 0, max = 1000, step = 1, value = 50),
        sliderInput('spec_type', 'Physician Speciaty Types in County', min = 0, max = 100, step = 1, value = 20),
        sliderInput('tier', 'Tier Number', min = 2, max = 10, step = 1, value = 5),
        sliderInput('premium', 'Monthy Premium($)', min = 0, max = 100, step = 1, value = 20),
        sliderInput('deductible', 'Annualy Deductible($)', min = 0, max = 500, step = 10, value = 100),
        sliderInput('copayment', 'Maximium Copayment Rate(%)', min = 0, max = 100, step = 1, value = 20),
        sliderInput('coinsurance', 'Maximium Coinsurance Rate(%)', min = 0, max = 50, step = 1, value = 25),
        submitButton("submit")
    ),
    
    mainPanel(
        h2('Drug and Health Plan Design Panel'),
        helpText("This application is for predicting the customer ratings for the drug and Health Plan"),
        h4('Internal Predictors:'),
        htmlOutput("internal"),
        
        h4('External Predictors:'),
        htmlOutput("external"),
        
        h4('Logistic Prediction Ratings:'),
        htmlOutput("ratings1"),
        
        h4('Dicision Prediction Ratings:'),
        htmlOutput("ratings2"),
        
        h4('Naive Bayes Ratings:'),
        htmlOutput("ratings4")
        
        #plotOutput('newPlot'),
        #textOutput("result")
    )
))