-- The purpose of this file is to abstract all DB call here for better organization and later optimizations.
RoleController = {}

function RoleController.GetAllRoles()
    return MySQL.query.await("SELECT * FROM roles")
end