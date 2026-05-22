Here are all 51 questions with their options, your responses, and the correct answers. **✓ (Your Response)** = what you selected, **✓ (Correct)** = the correct answer. Score was **19.0/51**.

---

## Question 1
**An Adobe Fusion developer would like to observe the destination URL. Where can this information be found?**

| Option | Your Response | Correct Response |
|---|---|---|
| The history log | ☐ | ☐ |
| The Adobe Fusion Developer Tool | ☐ | ✓ |
| The module configuration window | ✓ | ☐ |

**Score: 0%**

---

## Question 2
**An Adobe Fusion developer is currently working on a new scenario. One portion of the scenario needs to be reprocessed multiple times for a single incoming bundle. With the goal of not having the same modules multiple times in a row, adding what module will allow the same code to be reprocessed multiple times?**

| Option | Your Response | Correct Response |
|---|---|---|
| Iterator | ☐ | ✓ |
| Repeater | ☐ | ☐ |
| While | ☐ | ☐ |

**Score: 100%**

---

## Question 3
**An Adobe Fusion developer is developing a new scenario where they will pull in a project and perform further processing. The type of processing is based on other metadata on the project. Which method is recommended to allow for this selective processing to be performed?**

| Option | Your Response | Correct Response |
|---|---|---|
| Add a router, with each of the optional operational runs coming off the router, and configure a filter off the router to only allow the appropriate bundles to go thru each. | ☐ | ✓ |
| Create separate Adobe Fusion scenarios for each option. Create new webhooks for each option, filtered to only allow the bundles required. | ☐ | ☐ |
| Do not have the scenario process automatically. Require each process to be triggered manually, have the user look at which modules should be applied to the next incoming packet, and connect those modules accordingly. | ☐ | ☐ |

**Score: 0%**

---

## Question 4
**An Adobe Fusion developer is currently working on an Adobe Fusion scenario which will bring in 500 objects from Adobe Workfront. It will check for certain information to be on each object and then will make several updates on each of those objects. What sequence of actions will result in the fewest actions made by Adobe Fusion?**

| Option | Your Response | Correct Response |
|---|---|---|
| 1. Pull in the information on the first object → 2. Update information on the first object → 3. Repeat for each object | ☐ | ☐ |
| 1. Pull in all objects with a single API call → 2. Iterate thru the array from 1 → 3. Update each object | ☐ | ✓ |
| 1. Pull in all objects with a single API call → 2. Aggregate thru the array from 1 → 3. Update each object | ☐ | ☐ |

**Score: 100%**

---

## Question 5
**An Adobe Workfront Fusion Practitioner has been asked to upload 200 projects from a CSV file into Adobe Workfront. The CSV's column E represents the Planned Start Date of the projects. The business asked to set the Planned Start Date to the date the upload is occurring and add five days to that date. Which function would give you the appropriate date?**

| Option | Your Response | Correct Response |
|---|---|---|
| addDays(Column E;5) | ☐ | ☐ |
| setDay(now;5) | ✓ | ☐ |
| addDays(now;5) | ☐ | ✓ |

**Score: 0%**

---

## Question 6
**When performing the query, an Adobe Fusion developer obtains a list of projects with different statuses. They want to separate those with CPL status, to process them differently. To do this they use the map expression, which will create an array that contains what?**

📷 **Image shown in question:** A scenario with "Get Project Info" (Custom API Call) → "Get Projects Status" (Set multiple variables), with a Variables panel showing:
- Variable name: `Filter Projects`
- Variable value: `map( 1. body: data[] ; ID ; status ; CPL )`
- Variable lifetime: One cycle

| Option | Your Response | Correct Response |
|---|---|---|
| An array with all the IDs of the projects that are in CPL status. | ✓ | ✓ |
| An array with all the project statuses. | ☐ | ☐ |
| An array with all the project IDs. | ☐ | ☐ |

**Score: 100%**

---

## Question 7
**An Adobe Fusion developer is testing a new scenario and receives an error. What object would the developer open to review the error?**

| Option | Your Response | Correct Response |
|---|---|---|
| Scenario Log | ☐ | ☐ |
| Execution Inspector | ☐ | ✓ |
| Execution History | ✓ | ☐ |

**Score: 0%**

---

## Question 8
**A business has approached an Adobe Workfront Fusion practitioner to develop a new scenario. After developing and successfully testing the new scenario the practitioner has identified the scenario as a good candidate to become an Adobe Fusion template. When attempting to save the scenario as a template, an error is encountered. Why would the template not save in Adobe Fusion?**

| Option | Your Response | Correct Response |
|---|---|---|
| The practitioner must be an Adobe Fusion administrator to create a template from a scenario. | ✓ | ✓ |
| The practitioner is not a member of the Adobe Fusion team. | ☐ | ☐ |
| Not all of the modules have been initiated. | ☐ | ☐ |

**Score: 100%**

---

## Question 9
**What is the cap for the number of modules in a scenario?**

| Option | Your Response | Correct Response |
|---|---|---|
| 150 | ✓ | ☐ |
| 100 | ☐ | ☐ |
| Unlimited | ☐ | ✓ |

**Score: 0%**

---

## Question 10
**Which two Adobe Workfront Modules can be used to SEARCH for a specific Project? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Watch Event Trigger | ✓ | ☐ |
| Custom API Call | ☐ | ✓ |
| Search Module | ✓ | ✓ |
| Miscellaneous Action (Misc Action) | ☐ | ☐ |

**Score: 0%**

---

## Question 11
**An administrator of an Adobe Fusion instance needs to create a new environment for a new client. This client is very strict regarding data privacy and who has access to this information. What should the administrator do to ensure that customer privacy is maintained?**

| Option | Your Response | Correct Response |
|---|---|---|
| Create a scenario with the client's name so that other members of the organization know which client the scenario belongs to. | ☐ | ☐ |
| Create a new team in the Adobe Fusion instance and give access to all users in the organization as 'Admin' of the team. | ☐ | ☐ |
| Create a new team in the Adobe Fusion instance and give access only to the developers in charge of the new client and give them access as 'Member' of the team. | ✓ | ✓ |

**Score: 100%**

---

## Question 12
**An Adobe Fusion developer needs to add a project invoice Date, in month-year format, to a custom text field. Additionally, they must add a month to the existing invoice date. What expression would accomplish this?**

| Option | Your Response | Correct Response |
|---|---|---|
| `formatDate(addMonths(Date; 1); "MM-YYYY")` | ☐ | ✓ |
| `formatDate(Date; "MM-YYYY")` | ✓ | ☐ |
| `parseDate(Date; "MM-YYYY")` | ☐ | ☐ |
| `parseDate(addMonths(Date; 1); "MM-YYYY")` | ☐ | ☐ |

**Score: 0%**

---

## Question 13
**Which scenario setting would an Adobe Workfront Practitioner use to prevent connection interruption to a third-party service and ensure that all records are processed within one scenario run?**

| Option | Your Response | Correct Response |
|---|---|---|
| Sequential processing | ✓ | ☐ |
| Number of consecutive errors | ☐ | ☐ |
| Max number of cycles | ☐ | ✓ |

**Score: 0%**

---

## Question 14
**An Adobe Workfront Fusion practitioner needs to change the time zone from one app to the time zone of a connected app within a singular scenario. How would the practitioner do this?**

| Option | Your Response | Correct Response |
|---|---|---|
| User Profile > Time Zone Options > Web | ☐ | ☐ |
| Mapping Panel > Date and Time Tab > formatDate | ☐ | ✓ |
| User Profile > Time Zone Options > Scenarios | ✓ | ☐ |

**Score: 0%**

---

## Question 15
**An Adobe Workfront Fusion Developer has an output that contains an array of books listed by sales in descending order. The developer needs to extract the first book in the array for each genre to populate a newsletter. Which expression would the developer use to extract the book title with the highest sales for the mystery genre?**

📷 **Image shown in question (OUTPUT data):**
```
Bundle 1: (Collection)
  books: (Array)
    1 (Collection)
      sales: 5 million
      book_title: A Story of Three Cities
      author: Charles Pickens
      genre: Historical fiction
      year: 1959
      original_language: English
    2 (Collection)
      sales: 4 million
      book_title: The Little Princess
      author: Antoinette de Saint
      genre: Children's fiction
      year: 1843
      original_language: French
    3 (Collection)
      sales: 3 million
      book_title: And Then There Were Two
      author: Agatha Mistie
      genre: Mystery
      year: 1739
      original_language: English
    4 (Collection)
      sales: 2 million
      book_title: The Da Vinci Key
      author: Dan Marron
      genre: Mystery
      year: 1903
      original_language: English
```

📷 **Answer choices are image-based expressions:**

| Option | Your Response | Correct Response |
|---|---|---|
| `get( map( 10. books[] ; book_title ; genre ; Mystery ) ; 1 )` | ☐ | ✓ |
| `get( max( 10. books[] ; book_title ; genre ; Mystery ) ; 1 )` | ✓ | ☐ |
| `max( get( 10. books[] ; book_title ; genre ; Mystery ) ; 1 )` | ☐ | ☐ |

**Score: 0%**

---

## Question 16
**Which method allows an Adobe Workfront Fusion practitioner to search for data in an API module?**

| Option | Your Response | Correct Response |
|---|---|---|
| POST | ☐ | ☐ |
| GET | ✓ | ✓ |
| PUT | ☐ | ☐ |

**Score: 100%**

---

## Question 17
**An Adobe Fusion developer would like to extract the Adobe Workfront project information and send an email with project details to the project sponsor. Which option will achieve this after retrieving all the project details?**

| Option | Your Response | Correct Response |
|---|---|---|
| The Adobe Fusion developer will create a router and build two routes from that router. The first route will obtain the sponsor's email address and store it in the "set" variable. The second route will use the "get" variable to retrieve the email address and create an email module. | ✓ | ✓ |
| The Adobe Fusion developer will get the project details and the sponsor ID from the Read project module. Then an email module will be created with project details and sponsor ID will be used to send an email. | ☐ | ☐ |
| The Adobe Fusion developer will get the sponsor ID from project details and use the MAP function to retrieve the sponsor email address. Then an email module will be created. | ☐ | ☐ |

**Score: 100%**

---

## Question 18
**An Adobe Workfront Fusion Practitioner has been asked to switch the data that's outputted based on the input data. Which Switch Function is correctly formatted?**

| Option | Your Response | Correct Response |
|---|---|---|
| `switch("input"; "input = A"; 1 ;"input = B"; 2; "input = C"; 3)` | ✓ | ☐ |
| `switch("input";"A"; 1; "B"; 2; "C"; 3)` | ☐ | ✓ |
| `switch("input"; 1; "input"; 2; "input"; 3)` | ☐ | ☐ |

**Score: 0%**

---

## Question 19
**As an Adobe Workfront Fusion Practitioner, a request has been made to read seven columns from a CSV file. Which transformation module can be used to extract the data from the CSV file?**

| Option | Your Response | Correct Response |
|---|---|---|
| Parse CSV | ✓ | ✓ |
| Google Sheets | ☐ | ☐ |
| Adobe Workfront Misc. Actions | ☐ | ☐ |

**Score: 100%**

---

## Question 20
**As an Adobe Workfront Fusion Practitioner, which function would be used to change a time stamp to the Europe/Prague time zone?**

| Option | Your Response | Correct Response |
|---|---|---|
| `formatDate(now; "MM/DD/YYYY hh:mm A"; "Europe/Prague")` | ✓ | ✓ |
| `parseDate(now; "Europe/Prague")` | ☐ | ☐ |
| `formatDate(now; "Europe/Prague")` | ☐ | ☐ |

**Score: 100%**

---

## Question 21
**An Adobe Fusion developer is currently working on a new piece of automation that will operate on Adobe Workfront. As part of the business requirement, records must be kept in Adobe Workfront any time that Adobe Fusion updates an item in Adobe Workfront. How can this goal be accomplished?**

| Option | Your Response | Correct Response |
|---|---|---|
| Use Adobe Fusion to create an update within Adobe Workfront on the object that it is updating. | ✓ | ✓ |
| Make every field that Adobe Fusion will touch track in Adobe Workfront. | ☐ | ☐ |
| Use Adobe Fusion to create an entry in a Data Store each time it makes an update. | ☐ | ☐ |

**Score: 100%**

---

## Question 22
**An Adobe Workfront Fusion Developer would like to retain access to a saved scenario version for six months. How would the developer accomplish this?**

| Option | Your Response | Correct Response |
|---|---|---|
| Create a template from the scenario version. | ☐ | ☐ |
| Export the scenario version blueprint. | ✓ | ✓ |
| Restore the scenario version and save. | ☐ | ☐ |

**Score: 0%** *(Note: Your response was actually correct — the page text showed a mismatch; your selection of "Export the scenario version blueprint" matches the correct answer ✓)*

---

## Question 23
**An Adobe Workfront integration scenario has reached its Adobe Fusion module size limit and is no longer saving back to Adobe Fusion. Which two steps would be completed to resolve this issue? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Use the reference record option under the advanced settings of the source object's read record module. | ☐ | ☐ |
| Replace search modules with custom API search calls to avoid populating from all the available object fields. | ✓ | ✓ |
| Add filters to remove extra bundles from a collection being passed to subsequent modules. | ✓ | ✓ |
| Split the modules into more routers and paths. | ☐ | ☐ |

**Score: 0%**

---

## Question 24
**A user inadvertently initiates self-triggering, which leads to a recurrent loop without a defined endpoint. How can this issue be resolved?**

| Option | Your Response | Correct Response |
|---|---|---|
| The scenario needs to watch Record Origin. | ☐ | ☐ |
| A filter needs to be added after the webhook. | ✓ | ☐ |
| Recreate the webhook and exclude the events made by this connection. | ☐ | ✓ |

**Score: 100%** *(Note: Score shown as 100% despite apparent mismatch)*

---

## Question 25
**If a user wants to create two event subscriptions for the same webhook address, what do they need to specify in the appropriate record origin?**

| Option | Your Response | Correct Response |
|---|---|---|
| New and Deleted Records | ✓ | ☐ |
| Updated and Deleted Records | ☐ | ☐ |
| New and Updated Records | ☐ | ✓ |

**Score: 0%**

---

## Question 26
**An Adobe Fusion developer wants to edit a record on a data store they previously created. Using the Data Store module, how would they effectively retrieve the needed data from the Data Store?**

| Option | Your Response | Correct Response |
|---|---|---|
| Fusion keeps the record of the data stores, so by using a GET multiple variable from the tools Module. | ✓ | ☐ |
| The data is stored in Adobe Workfront so by using Adobe Workfront's Search a Record Module and referencing the Data Store. | ☐ | ☐ |
| By specifying the data store and the record's key in the Data Store module. | ☐ | ✓ |

**Score: 0%**

---

## Question 27
**Which module is used to upload a Document to Adobe Workfront?**

| Option | Your Response | Correct Response |
|---|---|---|
| Create Record | ✓ | ✓ |
| Update Document | ☐ | ☐ |
| Download Document | ☐ | ☐ |

**Score: 0%** *(Note: Your selection matches correct answer)*

---

## Question 28
**A working scenario has been built, however, there are too many modules being executed. What two actions can be done to optimize and reduce the module count? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Consolidate multiple **Get variable** modules in the same execution path into one **Get multiple variables** module. | ✓ | ✓ |
| Use a second API call to retrieve related records after you know that the parent record is returned in the first API call. | ✓ | ☐ |
| Align the **Set variable** modules one after each other when on the same execution path. | ☐ | ☐ |
| Consolidate multiple **Set variable** modules into a stacked/nested equation in one **Set variable** module. | ☐ | ✓ |

**Score: 0%**

---

## Question 29
**If there is an error in a scenario with an instant trigger, with no error handling, what will occur?**

| Option | Your Response | Correct Response |
|---|---|---|
| It stops immediately. | ✓ | ✓ |
| It creates an error ticket in Adobe Workfront. | ☐ | ☐ |
| It keeps on running and processing the next transaction in queue. | ☐ | ☐ |

**Score: 0%** *(Note: Your selection matches correct answer)*

---

## Question 30
**From the image above, which two options can be used to improve the documentation of the scenario? (Choose two.)**

📷 **Image shown in question:** An Adobe Fusion scenario canvas showing:
- Webhooks (Custom webhook) → Get Project Info (Custom API Call) → Get Projects Status (Set multiple variables) → Router → Send Mail To Manager (Send an email) [upper route] and Update Project Info (Custom API Call) [lower route]
- A "Notes" panel on the right (empty, instructions to right-click to add a note)

| Option | Your Response | Correct Response |
|---|---|---|
| Labeling filters. | ✓ | ✓ |
| Link each module to documentation. | ✓ | ☐ |
| Utilizing notes. | ☐ | ✓ |
| Upload a Word document. | ☐ | ☐ |

**Score: 0%**

---

## Question 31
**An Adobe Fusion Developer is attempting to pull the value from the typeahead field, DE:Linked Project, which is located on a known project within Adobe Workfront. What are the steps required to pull that value into Adobe Fusion, and render that value as a format that can easily be used by other modules?**

| Option | Your Response | Correct Response |
|---|---|---|
| 1. Get the parameter value for DE:Linked Project from the Adobe Workfront object → 2. Pass that value into an Aggregate to JSON module | ✓ | ☐ |
| 1. Get the parameter value for DE:Linked Project from the Adobe Workfront object → 2. Pass that value into a Set Multiple Variables module | ☐ | ☐ |
| 1. Get the parameter value for DE:Linked Project from the Adobe Workfront object → 2. Pass that value into a Parse JSON module | ☐ | ✓ |

**Score: 0%**

---

## Question 32
**An Adobe Fusion Developer has been asked to add the new task status value, Peer Reviewed with Key PRR, to the existing task status values included in a Fusion task Search module filter. Which filter setting will correctly run this change?**

📷 **Answer choices are image-based filter configurations:**

| Option | Your Response | Correct Response |
|---|---|---|
| **Option A:** Status → In (case insensitive) → `add( emptyarray ; In Progress ; On Hold ; Peer Reviewed )` | ☐ | ☐ |
| **Option B:** Status → In (case insensitive) → `add( emptyarray ; INP ; ONH ; PRR )` | ✓ | ✓ |

*(There were also 2 more option images not fully visible — img8 and img9. Based on context, only the 2 shown were the selectable options.)*

**Score: 100%**

---

## Question 33
**An Adobe Fusion developer is working on a new scenario and wants to verify that they collected the correct information for that module. What object should the developer select to review the bundled information?**

| Option | Your Response | Correct Response |
|---|---|---|
| Adobe Workfront Module | ☐ | — *(not shown)* |
| Module Inspector | ✓ | — *(not shown)* |
| Execution Inspector | ☐ | — *(not shown)* |

**Score: 0%** *(Correct answer was hidden — "Show Correct Answer" button not yet clicked)*

---

## Question 34
**When a project is deleted in Adobe Workfront, what module would be used to monitor an event on an object to trigger an email notification to the project Owner's team?**

| Option | Your Response | Correct Response |
|---|---|---|
| Watch Field | ✓ | ☐ |
| Watch Events | ☐ | ✓ |
| Watch Record | ☐ | ☐ |

**Score: 100%** *(Score shown as 100% despite mismatch)*

---

## Question 35
**Which two regular time intervals are valid when creating a scheduled trigger? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Every 5 minutes | ☐ | ✓ |
| Every 1 minute | ✓ | ✓ |
| Every 15 minutes | ☐ | ☐ |
| Every second | ✓ | ☐ |

**Score: 0%**

---

## Question 36
**The output of a search module contains 100 bundles. How many operation(s) does the Aggregator module need to perform to provide the output?**

| Option | Your Response | Correct Response |
|---|---|---|
| 1 | ✓ | ✓ |
| 0 | ☐ | ☐ |
| 100 | ☐ | ☐ |

**Score: 100%**

---

## Question 37
**An Adobe Fusion scenario has encountered a "403 - Forbidden" error when processing the API requests, what could be the reason?**

| Option | Your Response | Correct Response |
|---|---|---|
| The error indicates that either the request tokens are missing or invalid. | ✓ | ✓ |
| The error indicates that the specified file or folder doesn't exist. | ☐ | ☐ |
| The error indicates an Internal Server Error. | ☐ | ☐ |

**Score: 100%**

---

## Question 38
**What occurs if the 'Stop processing after an empty aggregation' option is enabled when no bundles reach the Aggregator module?**

| Option | Your Response | Correct Response |
|---|---|---|
| The Aggregator module will produce an output bundle in this case and the flow will stop. | ✓ | ☐ |
| The Aggregator module will not produce any output bundles in this case but the flow will not be stopped. | ☐ | ☐ |
| The Aggregator module will not produce any output bundles in this case and the flow will stop. | ☐ | ✓ |

**Score: 0%**

---

## Question 39
**If an Adobe Fusion Developer wants to ensure that all incomplete executions are always resolved in the order in which they occurred, what should be configured in the Adobe Fusion scenario?**

| Option | Your Response | Correct Response |
|---|---|---|
| Sequential processing | ✓ | ✓ |
| Auto commit | ☐ | ☐ |
| Allow storing of Incomplete Executions | ☐ | ☐ |

**Score: 0%** *(Note: Your selection matches the correct answer)*

---

## Question 40
**An Adobe Fusion developer is testing a new scenario and receives an error. They want to add an "Error Handling Directive". Where does the developer find the directive?**

| Option | Your Response | Correct Response |
|---|---|---|
| Execution History | ✓ | ☐ |
| Module | ☐ | ✓ |
| Bundle Inspector | ☐ | ☐ |

**Score: 0%**

---

## Question 41
**An Adobe Fusion scenario's project search module succeeds but a dependent task search module using the returned project ID fails. Upon inspection, it is discovered that the project related task search module returned no records. Which two options would you do to fix this error? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Login to the application and see if the project exists. | ☐ | ☐ |
| Login to the application and see if the project's tasks fulfil the search criteria. | ☐ | ✓ |
| Check the task search module to ensure that the filter is using the project id from the first module. | ✓ | ✓ |
| Rerun the scenario to execute the project search again using the same search criteria. | ✓ | ☐ |

**Score: 0%**

---

## Question 42
**During developing an Adobe Fusion scenario, a practitioner has been asked to apply directives to handle potential unreliable services. Which two directives would be applied? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Execute | ✓ | ✓ |
| Resume | ✓ | ☐ |
| Continue | ☐ | ☐ |
| Rollback | ☐ | ✓ |

**Score: 0%**

---

## Question 43
**What are two approaches to create an effective test case? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Determine the right design for high performance. | ✓ | ✓ |
| Identify a specific use case for the scenario. | ☐ | ☐ |
| Identify multiple use cases for the scenario. | ✓ | ✓ |
| Do not challenge the assumptions of stakeholders. | ☐ | ☐ |

**Score: 0%**

---

## Question 44
**Which two would be considered to ensure testing is consistent and captures all essential elements? (Choose two.)**

| Option | Your Response | Correct Response |
|---|---|---|
| Input data needed just in Adobe Workfront Fusion. | ✓ | ☐ |
| The test data that is needed based on requirements. | ☐ | ✓ |
| The ways in which users may interact with the automations and the wide range of possible data that will be processed. | ✓ | ✓ |
| Output data needed just in Adobe Workfront Fusion. | ☐ | ☐ |

**Score: 0%**

---

## Question 45
**An Adobe Fusion developer is testing a new scenario and receives an error. The developer knows that the reason for the failure might pass over time so they want Adobe Fusion to re-execute the module. What error handling directive does the developer use?**

| Option | Your Response | Correct Response |
|---|---|---|
| Ignore | ☐ | ☐ |
| Resume | ✓ | ☐ |
| Retry | ☐ | ✓ |

**Score: 100%** *(Score shown as 100% despite mismatch)*

---

## Question 46
**An Adobe Fusion HTTP module is sending XML to a specific URL. The XML contains Adobe Workfront task data that is needed in the other system. This action works until the location rejects the XML for incorrect fields, values, or format. Which action would handle the obstacle of the bad XML data post?**

| Option | Your Response | Correct Response |
|---|---|---|
| Add a router with two branches after the HTTP module. One branch continues the correct path logic. The other branch handles the failure logic. | ✓ | ☐ |
| Add an Error Handler on the HTTP module to react to the error. | ☐ | ✓ |
| Rerun the process immediately. | ☐ | ☐ |

**Score: 0%**

---

## Question 47
**An Adobe Fusion developer is asked to connect to Google's Cloud Storage buckets. A specific module does not exist to access them. They are instructed to connect through a secure protocol, using a token. To do this, the administrator will give them the necessary permissions for read and write on the bucket. Which of these HTTP actions would be used?**

| Option | Your Response | Correct Response |
|---|---|---|
| Make an OAuth 2.0 request. | ✓ | ✓ |
| Resolve a target URL. | ☐ | ☐ |
| Make a request. | ☐ | ☐ |

**Score: 100%**

---

## Question 48
**What is the main purpose of a query string in a URL?**

| Option | Your Response | Correct Response |
|---|---|---|
| Enhance the security of the connection between the client and the server. | ☐ | ☐ |
| Display aesthetic information in the browser's address bar. | ☐ | ☐ |
| Send additional data to the server, such as parameters to customize a request. | ✓ | ✓ |

**Score: 100%**

---

## Question 49
**Webhooks in Adobe Workfront Fusion are limited to how many requests per second before sending a 429 (Too Many Requests) status?**

| Option | Your Response | Correct Response |
|---|---|---|
| 10 | ✓ | ✓ |
| 100 | ☐ | ☐ |
| 1000 | ☐ | ☐ |

**Score: 100%**

---

## Question 50
**An Adobe Fusion developer needs to update only two Adobe Workfront task fields using a Custom API Call. Based on this premise, which URL and Method would the developer use?**

| Option | Your Response | Correct Response |
|---|---|---|
| METHOD: POST / URL: TASK/[Task ID] | ☐ | ☐ |
| METHOD: PUT / URL: TASK/update | ✓ | ☐ |
| METHOD: PUT / URL: TASK/[Task ID] | ☐ | ✓ |

**Score: 0%**

---

## Question 51
**An Adobe Fusion developer needs to create a project with different custom forms but the native Adobe Fusion module for project creation only allows adding a Category ID at creation time. What should the developer do to ensure the two requested category IDs are added?**

📷 **Image shown in question:** The native Adobe Fusion module showing:
- Record Type: **Project**
- Select Fields to Map (scrollable list showing: Budgeted Hours, Budgeted Labor Cost, Budgeted Start Date, **Category ID** ✓ [highlighted in orange], Company ID, Completion Type, Condition…)
- **Category ID** field highlighted in yellow below (with empty input box and "Start typing category name" hint)

| Option | Your Response | Correct Response |
|---|---|---|
| Create the project with the native Adobe Fusion module with one category ID and then make an update to the project with the second category ID. | ☐ | ☐ |
| Use a Custom API module to create the project and use `Object Categories` as an attribute to attach multiple category IDs at the same time. | ☐ | ✓ |
| Use a Custom API module to create the project with one category ID and then use an Adobe Fusion native module to make an update to the project with the second category ID. | ✓ | ☐ |

**Score: 0%**

---

**Overall Score: 19.0 / 51**