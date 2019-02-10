# Flirt Detector
## First phase report:
The program will required installation of package <code>simple-http</code>. 
<a href="https://docs.racket-lang.org/simple-http/index.html#%28form._%28%28lib._simple-http%2Fmain..rkt%29._json-requester%29%29">Link to the package can be found here.</a><br><br>
With the group idea of the project, we have successfully made API call using racket. The file final_project.rkt is the current working file.<br><br>
When you hit run, the program will open up a browser, asking for your google account permission so that the program can use that to send the server an http reuest for an access token.<br><br>
After you sign-in to your Google account, a token is granted, and on DrRacket console, there's a space for input. Write the sentence that you want to examined whether there is flirting intention in it or not.<br><br>
The program is currently using a test model that we created with 768 songs hand-classified. The csv data file for this model is <code>songs_test.csv</code>
## Project Architecture

