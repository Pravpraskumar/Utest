create or replace PACKAGE             "WP_PCK_GLOBALS" AS
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
    || 10.0.1.0    13-Feb-2020    PK          Initial version created
    || *******************************************************************************************
*/


---------------------------------------------------------------------------------------------------
PROCEDURE APEX_REDUCED_LOGIN(
      P_PROJ_ID          IN                 VARCHAR2,
      P_DP_ID            IN                 NUMBER,
      P_ROLE_ID          IN                 NUMBER,
      P_NLS_ID           IN                 NUMBER,
      P_USR_ID           IN                 VARCHAR2,
      P_MODULE_NAME      IN                 VARCHAR2,
      P_CLIENT_USER_ID   IN                 VARCHAR2 DEFAULT NULL,
      P_ACT_TRACE_IND    IN                 VARCHAR2 DEFAULT 'N'
    );

FUNCTION DECRYPT_PASSWORD(USERNAME IN M_SYS.M_USERS.M_USR_ID%TYPE,
                          PASSWORD IN M_SYS.M_USERS.PASSWORD%TYPE)
    RETURN VARCHAR2;

END WP_PCK_GLOBALS;
/
create or replace PACKAGE Body             "WP_PCK_GLOBALS" AS
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
    || 10.0.1.0    13-Feb-2020    PK          Initial version created
    || *******************************************************************************************
*/


---------------------------------------------------------------------------------------------------
PROCEDURE APEX_REDUCED_LOGIN(
      P_PROJ_ID          IN                 VARCHAR2,
      P_DP_ID            IN                 NUMBER,
      P_ROLE_ID          IN                 NUMBER,
      P_NLS_ID           IN                 NUMBER,
      P_USR_ID           IN                 VARCHAR2,
      P_MODULE_NAME      IN                 VARCHAR2,
      P_CLIENT_USER_ID   IN                 VARCHAR2 DEFAULT NULL,
      P_ACT_TRACE_IND    IN                 VARCHAR2 DEFAULT 'N'
    )AS
   BEGIN
      M_SYS.M_PCK_LOGIN_UTIL.REDUCED_LOGIN_EXT(P_PROJ_ID,P_DP_ID,P_ROLE_ID,P_NLS_ID,P_USR_ID,P_MODULE_NAME,P_CLIENT_USER_ID,P_ACT_TRACE_IND);
   END;

----------------------------------------------------Decrypt User Password-------------------------------------------------------

FUNCTION DECRYPT_PASSWORD(USERNAME IN M_SYS.M_USERS.M_USR_ID%TYPE,
                          PASSWORD IN M_SYS.M_USERS.PASSWORD%TYPE)
    RETURN VARCHAR2
    IS
    DEC_PWD VARCHAR2(10);
    BEGIN
        SELECT SUBSTR(
        M_PCK_CRYPT.DECRYPT(PASSWORD,M_PCK_CRYPT_KEY_CUSTOM.USER_KEY(USERNAME) ),
        INSTR(M_PCK_CRYPT.DECRYPT(PASSWORD,M_PCK_CRYPT_KEY_CUSTOM.USER_KEY(USERNAME) ),'~',1)+1,
        LENGTH(M_PCK_CRYPT.DECRYPT(PASSWORD,M_PCK_CRYPT_KEY_CUSTOM.USER_KEY(USERNAME) ))-
        INSTR(M_PCK_CRYPT.DECRYPT(PASSWORD,M_PCK_CRYPT_KEY_CUSTOM.USER_KEY(USERNAME) ),'~',1)
        )
        INTO DEC_PWD
        FROM M_SYS.M_USERS
        WHERE M_USR_ID =USERNAME;
        RETURN DEC_PWD;
    END;

END WP_PCK_GLOBALS;
/
