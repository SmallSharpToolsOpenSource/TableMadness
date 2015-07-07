TableMadness
=============

A sample project which shows how to add and remove rows from a UITableView in iOS

Keeping a `UITableView` in sync with data which is fetched from a remote data source 
can be tricky. Adding, removing and reloading specific rows in the table has to be managed 
carefully to prevent internal inconsistencies which will cause an exception and crash.

This sample project uses a model object, `SSTItem` which simply holds onto properties 
for `number`, `identifier` and `modified` so that each object instance can be uniquely 
identified in an array and updated with a new number. The `modified` property is 
updated with the current time when the number is changed, which causes the table to 
reload that row instead of removing and adding it.

The table view update is run in a `@synchronized` block because updating the view can 
trigger it to reload data at an inconvient time, cause an inconsistency exception and a 
crash.

This code is built so this example can be used in a real app which needs to keep table 
data updated with a model which is changing without user interaction, such as a background 
fetch of updated data.

------

Brennan Stehling  
[SmallSharpTools](http://www.smallsharptools.com/)  
[@smallsharptools](https://twitter.com/smallsharptools) (Twitter)  
