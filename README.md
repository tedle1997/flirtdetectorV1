# Flirt Detector
## First phase report:
The program will required installation of package <code>simple-http</code>. 
<a href="https://docs.racket-lang.org/simple-http/index.html#%28form._%28%28lib._simple-http%2Fmain..rkt%29._json-requester%29%29">Link to the package can be found here.</a><br><br>
With the group idea of the project, we have successfully made API call using racket. The file final_project.rkt is the current working file.<br><br>
When you hit run, the program will open up a browser, asking for your google account permission so that the program can use that to send the server an http reuest for an access token.<br><br>
After you sign-in to your Google account, a token is granted, and on DrRacket console, there's a space for input. Write the sentence that you want to examined whether there is flirting intention in it or not.<br><br>
The program is currently using a test model that we created with 964 songs hand-classified. The csv data file for this model is <code>data.csv</code>

## Project Architecture

This project is built upon 3 fundamental technology:<br>
1. Google AutoML Natural Language API
2. #lang racket
3. Human dedication and ingenuity

### 1. Google AutoML Natural Language API:
The API helps training the model for prediction by feeding it a csv file with labels in the ending column. The API will run the data through a pipeline of model from Google and release the best model. An API call with Open Authentication 2.0 is needed to use the model as an online classifier.<br><br>
! Note: The app is currently running without a proper server-client architecture, so to use the app, we have to get your email and set permission in the Google IAM permission.<br><br>
Send your google mail or account to thuongle23081997@gmail.com for permission to use the app. It takes roughly 48 hours to process the request.

### 2. Racket:
Racket comes into the picture as the main mechanism to process the OAuth2.0 authorization procedure. We handle this specific part in a different thread to guarantee that the program can work parallelly while the servlet is recieving authentication.

The GUI is also constructed using Racket. The GUI library inside Racket is built on Object Oriented Programming, so we used that extensively inside the GUI. The GUI recieve user's input, then send it to the API for prediction. After recieving the prediction, the GUI display the prediction in the form of a radar chart.

### 3. Human ingenuity:
The hardest part of the project was the data itself, since there is no open-source data on how an individual talk to another individual. Hence, the idea of using an alternative data  for the model to study human behavior comes into play. We choose song lyrics as our context study point for that it fits the length of a an extended conversation and the context of a song is more constant than the context of a book or similar data type.<br><br>

## Conclusion:
This is only the beginning of our research. From this project, we want to expand the posibility of making a working application for extensive usage in dating apps or in anti online sexual harassment. We look forward to any contribution for this open-source project.