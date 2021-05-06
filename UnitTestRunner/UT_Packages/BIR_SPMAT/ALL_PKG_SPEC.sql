PROMPT Creating Package 'WP_LOGIN'

create or replace PACKAGE             "WP_LOGIN" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Login
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/


---------------------------------------------------------Type Defnition---------------------------------------------------------
TYPE MOCK_TAB_T IS
      TABLE OF VARCHAR2(4000)INDEX BY VARCHAR2(255);
--------------------------------------------------------------------------------------------------------------------------------   
MOCK_TAB    MOCK_TAB_T;
G_USR_ID    M_SYS.M_USERS.M_USR_ID%TYPE;
G_PROJ_ID   M_SYS.M_PROJECTS.PROJ_ID%TYPE;
G_DP_ID     M_SYS.M_DISCIPLINES.DP_ID%TYPE;
G_ROLE_ID   M_SYS.M_APPL_ROLES.ROLE_ID%TYPE;
--------------------------------------------------------------------------------------------------------------------------------

    PROCEDURE CREATE_SESSION(P_APP_ID IN NUMBER, 
                             P_NLS_ID IN NUMBER);

    PROCEDURE REDUCED_LOGIN(
      P_PROJ_ID          IN                 VARCHAR2,
      P_DP_ID            IN                 NUMBER,
      P_ROLE_ID          IN                 NUMBER,
      P_NLS_ID           IN                 NUMBER,
      P_USR_ID           IN                 VARCHAR2,
      P_MODULE_NAME      IN                 VARCHAR2,
      P_CLIENT_USER_ID   IN                 VARCHAR2 DEFAULT NULL,
      P_ACT_TRACE_IND    IN                 VARCHAR2 DEFAULT 'N'
    );

END WP_LOGIN;
/
SHOW ERROR

PROMPT Creating Package 'WP_LANGUAGES_CUD'

create or replace PACKAGE             "WP_LANGUAGES_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Languages
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/
--------------------------------------------------------------------------------------------------------------------------------
GCR_NUMBER NUMBER;
--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------

    PROCEDURE LANGUAGE_SCREEN_WFLOWS;

    PROCEDURE DELETE_LANGUAGE_AFTER_USE(P_NLS M_SYS.M_NLS.NLS_ID%TYPE);

-------------------------------------------------------Public Functions---------------------------------------------------------

    FUNCTION CREATE_LANGUAGE_TO_USE(P_DESC M_SYS.M_NLS.NLS_ID%TYPE)
    RETURN NUMBER;

--------------------------------------------------------------------------------------------------------------------------------
end WP_LANGUAGES_CUD;
/
SHOW ERROR

PROMPT Creating Package 'WP_DISCIPLINES_CUD'

create or replace PACKAGE             "WP_DISCIPLINES_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Disciplines
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------

    FUNCTION INSERT_DISP (P_DP_CODE     IN M_SYS.M_DISCIPLINES.DP_CODE%TYPE,
                          P_ABBREV      IN M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE)
    RETURN NUMBER;

    PROCEDURE INSERT_DPID(P_DP_CODE     IN M_SYS.M_DISCIPLINES.DP_CODE%TYPE,
                          P_ABBREV      IN M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE);

    PROCEDURE DEL_DISP(P_DP_ID IN M_SYS.M_DISCIPLINES.DP_ID%TYPE,
                       P_NLS_ID IN M_SYS.M_NLS.NLS_ID%TYPE);

    PROCEDURE DISCIPLINES_SCREEN_WFLOWS;


end WP_DISCIPLINES_CUD;
/
SHOW ERROR

PROMPT Creating Package 'WP_USER_GROUPS_CUD'

create or replace PACKAGE             "WP_USER_GROUPS_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Disciplines
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
P_UGR_CODE M_SYS.M_USER_GROUPS.UGR_CODE%TYPE;
--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------


    PROCEDURE USERGROUP_SCREEN_WFLOWS;


end WP_USER_GROUPS_CUD;
/
SHOW ERROR

PROMPT Creating Package 'WP_PROJ_GROUPS_CUD'

create or replace PACKAGE             "WP_PROJ_GROUPS_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Disciplines
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
P_PGR_CODE M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE;
--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------

    FUNCTION INSERT_PGRP (P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE,
                          P_PGR_CODE    IN M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_PROJECT_GROUP_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_PROJECT_GROUP_NLS.DESCRIPTION%TYPE)
    RETURN NUMBER;

    PROCEDURE DEL_PGRP(P_PGR_ID      IN M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE,
                       P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE);

    PROCEDURE PROJECT_GROUPS_SCREEN_WFLOWS;


end WP_PROJ_GROUPS_CUD;
/
SHOW ERROR

PROMPT Creating Package 'WP_PROD_GROUPS_CUD'

create or replace PACKAGE             "WP_PROD_GROUPS_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Product Groups
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    16-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------


    PROCEDURE PRODUCT_GROUP_SCREEN_WFLOWS;


end WP_PROD_GROUPS_CUD;
/

SHOW ERROR

PROMPT Creating Package 'WT_MAT_ADM1'

create or replace PACKAGE             "WT_MAT_ADM1" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow Package for Running TestCases
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--%suite(WF-1: Create Product Group)
--%suitepath(WF_ADMIN_APEX1)
--%rollback(manual)

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------
--%test(Login Screen Workflows)
    PROCEDURE LOGIN_WF;
    
--%test(Languages Screen Workflows)
    PROCEDURE LANGAUGES_WF;

--%test(Disciplines Screen Workflows)
    PROCEDURE DISCIPLINES_WF;

--%test(User Group Screen Workflows)
    PROCEDURE USERGROUP_SCREEN_WF;
    
--%test(Project Group Screen Workflows)
    PROCEDURE PROJECT_GROUPS_WF;

--%test(Product Group Screen Workflows)
    PROCEDURE PRODUCT_GROUPS_WF;


end WT_MAT_ADM1;
/
SHOW ERROR

PROMPT Creating Package 'WP_USERS_CUD'

create or replace PACKAGE             "WP_USERS_CUD" is
/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Users
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 10.0.        21-Feb-2020    Misbah       Initial version created
    || *******************************************************************************************
*/

 
PROCEDURE USER_SCREEN_WORKFLOWS;

end WP_USERS_CUD;
/
SHOW ERROR

PROMPT Creating Package 'WP_ROLES_CUD'

create or replace PACKAGE             "WP_ROLES_CUD" IS

/*
    || *******************************************************************************************
    || Author:  Christoph Hegerath (CH)
    ||
    || Purpose: Workflow package for Roles
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 10.1.0.0     07-Jan-2020    Christoph    Initial version created
    || 10.1.0.0     16-Mar-2020    Praveen      Updated Package to Support Workflow tests
    || *******************************************************************************************
*/


   PROCEDURE ROLES_SCREEN_WORKFLOWS;
   
   PROCEDURE ROLES_SCREEN_WORKFLOWS1;


END "WP_ROLES_CUD";
/
SHOW ERROR

PROMPT Creating Package 'WT_MAT_ADM2'

create or replace PACKAGE             "WT_MAT_ADM2" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow Package for Running TestCases
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--%suite(WF-2: Create User and Assign User Security)
--%suitepath(WF_ADMIN_APEX2)
--%rollback(manual)

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------
--%test(Login Screen Workflows)
    PROCEDURE LOGIN_WF;   

--%test(Users Screen Workflows)
    PROCEDURE USERS_WF;

--%test(Roles Screen Workflows)
    PROCEDURE ROLES_WF;
    
--%test(Roles Screen Workflows-1)
    PROCEDURE MAP_MENUS_TO_ROLES_WF;



end WT_MAT_ADM2;
/
SHOW ERROR

