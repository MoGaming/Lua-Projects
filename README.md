# Lua-Projects
Random projects I've made, all compiled into one package while being easy to switch between. These were made over the course of 3 years (2021-09-05 to 2024-08-29).

Feel free to use parts of the code for your own projects, these are some explanations behind them: 

* I created the modulo projectile bounce for a generalization of reflection for games with lots of projects but basic square map boundries. 
This can be combined with a raytracer or raymarcher to check if the projectile has hit another object and reflect off of, allowing for both "active" and "passive" reflections.

* Boids, also known as bird-like objects, were created and named by Craig Reynolds in 1986. 
I implemented my own version using Lua and a grid-based query system to limit the amount of checks each boid makes in order to increase preformance and reduce useless checks.
Although it isn't as prefect as I'd like it to be due to complications with square boundaries around the corners, it looks very natural with only higher boid counts (2000+) resulting in weird patterns caused by overlapping and seperation vs cohesion strength.

* One of the folders included renders a "Mandelbrot set" with a quick pass over, the user can zoom and move around the camera and render more and more higher resolution images to see how detailed the fractal gets. Disable the "Mandelbrot set" to render a "Lyapunov fractal".
Some of the code was based on other implementations of the code, I have no use for this one in particular outside of rendering it as I only made it because I was bored and heard others had trouble with it, it took me around an hour or two to code.

Smaller Projects, these are also some quick explanations:

* DFA Solver is still WIP but I plan to automatically generate valid solutions to state diagrams, it was made while talking to a couple of my peers about DFAs, something that at the time I had no clue about.
* Radial Prime Numbers was made to visualize the spiral of prime numbers, I got the idea from a video on the topic made by 3Blue1Blue.
* Test Game was my first project, I followed a tutorial while making it but got bored early on and busy with University.
* Random Image is based off the Library of Babel, but instead of books, it randomly generates image with standardized size and coloured pixels. I wanted to add a seed and a reverse seed so I could look up images that I upload but I never got the time to do that.


Note: This is my first real github repo used to share code for others to use, I had no clue why I decided to redo the code to all run from one main lua file instead of just uploading each project's folder with its own main file instead of the current module lua file.
