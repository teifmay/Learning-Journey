📚 Learning Streak App
A mobile application designed to help users establish and maintain a daily learning habit through streak tracking, learning goals, and a "Freeze" mechanism to prevent streak loss.

✨ Features
Daily Activity Tracking: Log your learning activity each day to build your streak.
Streak Management: Visually track your current streak on the main activity screen.
Learning Goal Setting: Set and update specific learning goals over Week, Month, or Year periods (e.g., "I want to learn Rouran").
"Freeze" Functionality: Use a limited number of "Freezes" to prevent losing your streak on an unlogged day.
Activity History: A calendar view to see all previous days logged as learned or frozen.

⚙️ Key Concepts & Business Logic
Streak and Freeze Rules:
The "Freeze" mechanism is designed to prevent a user from losing their streak.
Freeze Allotment: Users have a limited number of freezes:
2 Freezes per week.
5 Freezes per month.
96 Freezes per year.
Streak Break: A streak is lost if the user spends more than 32 hours without logging a day and without using a Freeze.
Daily Log Timing: A day is considered logged if the user logs their learning activity before 11 PM.
If the user has not logged by 10 AM on the following day, the button to log the previous day will be disabled.
Goal Management:
Users can Set new learning goals or Update existing goals (Task 4 in design).
Goals can be defined by a subject and a timeframe (Week, Month, Year).
When a goal is completed, a "Goal completed" message is shown, prompting the user to set a new goal.

📱 Screens & Tasks (Referencing Design)
The app flow covers the following main user tasks:
Onboarding: Initial setup where the user declares what they want to learn.
Log a day: Main screen shows options to Log as Learned or Log as Frozen.
Streak and Goal Completion: Views for the Last day of the streak and Goal completion.
Change/Update Learning Goal: Screens for setting a new goal or updating the current one.
Activity Calendar: A chronological calendar view to see all past logged (blue circle) and potentially frozen/unlogged days (orange/brown circle).

👨‍💻 Development Notes (For Developers)
Date/Time Handling: Pay special attention to timezone and the specific cutoff times for logging (11 PM) and disabling the log button (10 AM the next day).
Focus Logic: The system relies on a "Days" based calculation for the Freeze counter, not "Day" (singular).
Calendar Colors: The calendar view uses distinct colors to denote different states (e.g., Learned, Current Day, Not Logged).
