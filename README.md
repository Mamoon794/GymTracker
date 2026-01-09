# GymTracker
This gym tracker is written in swift so that it can take advantage of iphone's native UI. This allows for easy animation implementation like hiding toolbar.

# ✨ Features
* Ability to create and add a workout's reps and sets
* Statistics tab which shows workout frequency and 1 rep max weight for a selected workout
* A calendar view to show which days were gym days
* A list view to show workouts sorted by date in a list format


# Technical Implementation
* The app follows Model View Controller Scheme in which each view has it's own seperate file
* The database is written in a `excercise.swift` inside `Models` folder and the operations to add, remove, update models is written in `dbOperations.swift`.
* Any functionality that's being used in more than one place, is written in a seperate file to reduce redundancy and improve scalability
