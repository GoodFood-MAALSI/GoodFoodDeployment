// mongo-init.js
db.auth("mongouser", "j2.kP-tA+hM_zC@xV=nE"); // Authenticate as the root user first

// Switch to the target database
var targetDb = db.getSiblingDB("goodfood_delivery_geolocation");

// Create a dummy collection to ensure the database exists (if it doesn't already)
targetDb.createCollection("initial_collection"); 

// Create or update the 'mongouser' with specific roles on the target database
targetDb.createUser(
   {
     user: "mongouser",
     pwd: "j2.kP-tA+hM_zC@xV=nE", // Use the unencoded password here
     roles: [
       { role: "readWrite", db: "goodfood_delivery_geolocation" }
     ]
   }
);

// If you need more general permissions (e.g., for development) you could also do:
// db.getSiblingDB("admin").grantRolesToUser(
//    "mongouser",
//    [
//      { role: "readWriteAnyDatabase", db: "admin" } // Grants read/write to all databases
//    ]
// );