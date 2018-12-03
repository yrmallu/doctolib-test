## Doctolib Coding Test

The goal is to write an algorithm that finds availabilities in an agenda depending on the events attached to it.
The main method has a start date for input and is looking for the availabilities over the next 7 days.

There are two kinds of events:

 - 'opening', are the openings for a specific day and they can be reccuring week by week.
 - 'appointment', times when the doctor is already booked.
 
To init the project:

``` sh 
rails new doctolib-test
rails g model event starts_at:datetime ends_at:datetime kind:string weekly_recurring:boolean
```

