PROMPT Creating Package body 'WP_LOGIN'

create or replace PACKAGE BODY WP_LOGIN AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Login
    ||
    || Taken Reference from the Global Package Created by Andreas Lueke
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    07-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

-----------------------------------------------------Private Functions----------------------------------------------------------

---------------------------------------------------Initialize Apex Session------------------------------------------------------
    PROCEDURE INITIALIZE_SESSION(P_USERNAME IN M_SYS.M_USERS.M_USR_ID%TYPE,
                                 P_PASSWORD IN M_SYS.M_USERS.PASSWORD%TYPE,
                                 P_APPLICATION IN NUMBER)
    IS
    L_WORKSPACE_ID      APEX_APPLICATIONS.WORKSPACE_ID%TYPE;
    L_APPLICATION_ID    NUMBER;
    L_PAGE_ID           NUMBER;
    L_SESSION           NUMBER;
    BEGIN
        BEGIN
            -- Clean up Mock_Table
            MOCK_TAB.DELETE(); 
            --If session is already valid - just clean the state for the Mentioned Application
            -- All apex_session.setItems are cleared now
            IF(NVL(APEX_CUSTOM_AUTH.GET_SESSION_ID,0)> 0)THEN
                BEGIN
                    IF APEX_APPLICATION.G_FLOW_ID = P_APPLICATION THEN
                        APEX_UTIL.CLEAR_APP_CACHE(P_APPLICATION);
                        RETURN;
                    ELSE
                        APEX_SESSION.DELETE_SESSION(P_SESSION_ID => APEX_CUSTOM_AUTH.GET_SESSION_ID);
                    END IF;
                END;
            END IF;

            -- Get Workspace Ready and init session for apex

            L_APPLICATION_ID    := P_APPLICATION;
            L_PAGE_ID           := 1;

            SELECT
             WORKSPACE_ID INTO L_WORKSPACE_ID
            FROM
             APEX_APPLICATIONS
            WHERE
             APPLICATION_ID = L_APPLICATION_ID;

            APEX_UTIL.SET_SECURITY_GROUP_ID(L_WORKSPACE_ID);
            APEX_APPLICATION.G_INSTANCE     := 1;
            APEX_APPLICATION.G_FLOW_ID      := L_APPLICATION_ID;
            APEX_APPLICATION.G_FLOW_STEP_ID := L_PAGE_ID;

            L_SESSION := APEX_CUSTOM_AUTH.GET_NEXT_SESSION_ID;
            APEX_CUSTOM_AUTH.DEFINE_USER_SESSION(P_USERNAME,L_SESSION);
        END;

        -- Do the Login Steps 1&2 (Reference to APEX Documentation)
        -- Cover some exceptions from the Interal framework issues
        BEGIN
            APEX_CUSTOM_AUTH.LOGIN( P_UNAME     => P_USERNAME,
                                    P_PASSWORD     => P_PASSWORD,
                                    P_SESSION_ID   => L_SESSION);



            --DBMS_OUTPUT.PUT_LINE('AUTHENTICATION LOGIN DONE');
            UT.EXPECT('AUTHENTICATION LOGIN DONE','Authentication Failed').TO_EQUAL('AUTHENTICATION LOGIN DONE');
        EXCEPTION
            WHEN OTHERS THEN
                IF (SQLCODE = -20987) THEN
                    NULL; -- suppresses Apex Internal Error
                ELSIF  (SQLCODE = -20876) THEN
                    NULL; -- suppresses STOP APEX ENGINE because of application switch
                ELSE
                    RAISE;
                END IF;
        END;



        BEGIN
            APEX_CUSTOM_AUTH.POST_LOGIN(P_UNAME => P_USERNAME,P_SESSION_ID => L_SESSION,P_APP_PAGE => APEX_APPLICATION.G_FLOW_ID
                                                                                                   || ':'
                                                                                                   || L_PAGE_ID);

            DBMS_OUTPUT.PUT_LINE('AUTHENTICATION-APP'||APEX_APPLICATION.G_FLOW_ID||' POST_LOGIN DONE');
            UT.EXPECT('AUTHENTICATION POST_LOGIN DONE','Authentication Failed').TO_EQUAL('AUTHENTICATION POST_LOGIN DONE');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20987 THEN
                    NULL; -- suppresses Apex Internal Error
                ELSE
                    RAISE;
                END IF;
        END;



   END INITIALIZE_SESSION;
----------------------------------------------------Public Procedures-----------------------------------------------------------

-------------------------------------------------------Create Session-----------------------------------------------------------
    PROCEDURE CREATE_SESSION(P_APP_ID IN NUMBER, 
                         P_NLS_ID IN NUMBER)
    IS
    P_USER          M_SYS.M_USERS.M_USR_ID%TYPE;
    P_PASSWORD      M_SYS.M_USERS.PASSWORD%TYPE;
    DEC_PASSWORD    VARCHAR2(20 CHAR);
    BEGIN
        --Set the Global User Security from the Database
        SELECT 
            M_USR_ID, PROJ_ID, DP_ID, ROLE_ID
        INTO 
            G_USR_ID, G_PROJ_ID, G_DP_ID, G_ROLE_ID
        FROM 
            M_SYS.M_USER_SECURITIES
        WHERE 
            NLS_ID = P_NLS_ID AND ROWNUM = 1;

        --Pull user credentials
        SELECT
            M_USR_ID, PASSWORD
        INTO
            P_USER, P_PASSWORD
        FROM
            M_SYS.M_USERS
        WHERE
            M_USR_ID = G_USR_ID;

        --Get the Decrypted Password
        DEC_PASSWORD := M_SYS.WP_PCK_GLOBALS.DECRYPT_PASSWORD(P_USER,P_PASSWORD);

        --Initialize Session
        INITIALIZE_SESSION(P_USER,P_PASSWORD,P_APP_ID);

    END;

    PROCEDURE REDUCED_LOGIN(
      P_PROJ_ID          IN                 VARCHAR2,
      P_DP_ID            IN                 NUMBER,
      P_ROLE_ID          IN                 NUMBER,
      P_NLS_ID           IN                 NUMBER,
      P_USR_ID           IN                 VARCHAR2,
      P_MODULE_NAME      IN                 VARCHAR2,
      P_CLIENT_USER_ID   IN                 VARCHAR2 DEFAULT NULL,
      P_ACT_TRACE_IND    IN                 VARCHAR2 DEFAULT 'N'
    )
    IS
    BEGIN
      M_SYS.WP_PCK_GLOBALS.APEX_REDUCED_LOGIN(P_PROJ_ID,P_DP_ID,P_ROLE_ID,P_NLS_ID,P_USR_ID,P_MODULE_NAME,P_CLIENT_USER_ID,P_ACT_TRACE_IND);
    END REDUCED_LOGIN;



end WP_LOGIN;
/
SHOW ERROR

PROMPT Creating Package body 'WP_LANGUAGES_CUD'

create or replace PACKAGE BODY             "WP_LANGUAGES_CUD" AS

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
P_NLS M_SYS.M_NLS.NLS_ID%TYPE;
---------------------------------------------------Private Functions------------------------------------------------------------
    FUNCTION GET_AVAILABLE_NLSID
    RETURN NUMBER
    IS
        NLSID_AVAILABLE  NUMBER;
        V_ID             NUMBER;
    BEGIN
        FOR I IN 1..99
        LOOP
            SELECT NVL(MAX(1),0) INTO V_ID FROM DUAL WHERE I NOT IN (SELECT NLS_ID FROM M_SYS.M_NLS);
            IF(V_ID =1) THEN
                NLSID_AVAILABLE:=I;
                EXIT;
            END IF;
        END LOOP;

        RETURN NLSID_AVAILABLE;
    END;

--------------------------------------------------------------------------------------------------------------------------------
FUNCTION SET_NLS_RECORD (ROWNUMBER      NUMBER)
    RETURN NUMBER
    IS
    NLS_COUNT   NUMBER;
    V_NLS       PLS_INTEGER;
    V_ROW_ID    VARCHAR2(100);
    BEGIN
        SELECT COUNT(*) INTO NLS_COUNT FROM M_SYS.M_NLS;
        IF(NLS_COUNT>(ROWNUMBER-1)) THEN
            SELECT NLS_ID INTO V_NLS FROM (SELECT MN.*, ROWNUM as ORD FROM M_SYS.M_NLS MN) WHERE ORD = ROWNUMBER;
        ELSE
            V_NLS    := GET_AVAILABLE_NLSID();
            V_ROW_ID := BIR_SPMAT.ADM_P40011.INSERT_LANGUAGES(V_NLS,'ENGLISH-'||ROWNUMBER,'Y','NLS_LANGUAGE');
        END IF;  
        RETURN V_NLS;
END SET_NLS_RECORD;
--------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE DEL_COMMITED_NLS (P_NLS NUMBER)
    IS
    BEGIN
        IF(P_NLS IS NOT NULL) THEN
            DELETE FROM M_SYS.M_APPL_MENU_NLS WHERE NLS_ID=P_NLS;
            DELETE FROM M_SYS.M_APPL_PARM_NLS WHERE NLS_ID=P_NLS;
            DELETE FROM M_SYS.M_NLS WHERE NLS_ID=P_NLS;
            COMMIT;
        END IF;
    END DEL_COMMITED_NLS;
---------------------------------------------------Private Procedures-----------------------------------------------------------    
    PROCEDURE INSERT_NLSID(P_NLS_ID IN M_SYS.M_NLS.NLS_ID%TYPE,
                           P_DESC   IN M_SYS.M_NLS.DESCRIPTION%TYPE,
                           P_GNLS   IN M_SYS.M_NLS.USE_GEN_NLS%TYPE)
    IS
        L_COUNT1    PLS_INTEGER;
        V_ROW_ID    VARCHAR2(100);
        V_NLS_ID    VARCHAR2(10);
    BEGIN
        --Arrange
        V_ROW_ID := BIR_SPMAT.ADM_P40011.INSERT_LANGUAGES(P_NLS_ID,P_DESC,P_GNLS,'NLS');
        --Act
        --Get Expected Value
        SELECT NLS_ID INTO V_NLS_ID FROM M_SYS.M_NLS WHERE ROWID=V_ROW_ID;
        SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_NLS WHERE NLS_ID = V_NLS_ID;
        --Assert
        DBMS_OUTPUT.PUT_LINE('Language '||P_DESC||' Created');
        UT.EXPECT(L_COUNT1,'NLS ID Not Insertion failed').TO_EQUAL(1);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
    END INSERT_NLSID;

--------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE UPDATE_LANG(P_NLS_ID IN M_SYS.M_NLS.NLS_ID%TYPE,
                          P_DESC   IN M_SYS.M_NLS.DESCRIPTION%TYPE,
                          P_GNLS   IN M_SYS.M_NLS.USE_GEN_NLS%TYPE)
    IS
        V_NLS             NUMBER;
        V_DUP             NUMBER;
        L_DES             VARCHAR2(70 CHAR);
        E_DES             VARCHAR2(70 CHAR);              
    BEGIN
        --Arrange
        --Act
        BIR_SPMAT.ADM_P40011.UPDATE_LANGUAGES(P_NLS_ID,'SPANISH','N');
        --Get Actual Value
        SELECT DESCRIPTION INTO L_DES FROM M_SYS.M_NLS WHERE NLS_ID = V_NLS;
        --Assert
        UT.EXPECT(L_DES).TO_EQUAL('SPANISH');
    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(100);

    END UPDATE_LANG;
-----------------------------------------Delete Languages from the Table M_NLS--------------------------------------------------
    PROCEDURE DEL_LANG(P_NLS_ID IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    L_COUNT1    PLS_INTEGER;
    L_COUNT2    PLS_INTEGER;
    L_EXPECTED  SYS_REFCURSOR;
    L_ACTUAL    SYS_REFCURSOR;
BEGIN
    --Arrange
    SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_NLS;
    OPEN L_EXPECTED FOR SELECT NLS_ID,DESCRIPTION,USE_GEN_NLS FROM M_SYS.M_NLS;
    --Act
    BIR_SPMAT.ADM_P40011.DELETE_LANGUAGES(P_NLS_ID,1,'NLS');
    --Get Actual Value
    OPEN L_ACTUAL FOR SELECT NLS_ID,DESCRIPTION,USE_GEN_NLS FROM M_SYS.M_NLS;
    SELECT COUNT(1) INTO L_COUNT2 FROM M_SYS.M_NLS WHERE NLS_ID = P_NLS_ID;
    --Assert
    UT.EXPECT(L_EXPECTED).TO_EQUAL(L_ACTUAL);
    UT.EXPECT(L_COUNT2).TO_EQUAL(1);

EXCEPTION
        WHEN OTHERS THEN
        UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
END DEL_LANG;

-------------------------------------------------------Public Procedures--------------------------------------------------------

    PROCEDURE LANGUAGE_SCREEN_WFLOWS
    IS
    V_NLS M_SYS.M_NLS.NLS_ID%TYPE;
    BEGIN
        --Get Next Available NLS ID value
        V_NLS := GET_AVAILABLE_NLSID();
        --Insert new NLS ID Language
        INSERT_NLSID(V_NLS,'LANG-'||V_NLS,'N');
        GCR_NUMBER := V_NLS;
        --Update Created NLS Language
        --UPDATE_LANG(V_NLS,'SPANISH','N');
        --Delete Created NLS Language
        --DEL_LANG(V_NLS);
        --Rollback
        --DEL_COMMITED_NLS(V_NLS);
    END;
--------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE DELETE_LANGUAGE_AFTER_USE(P_NLS M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    BEGIN
        DEL_COMMITED_NLS(P_NLS);
    END;
--------------------------------------------------------------------------------------------------------------------------------
    FUNCTION CREATE_LANGUAGE_TO_USE(P_DESC M_SYS.M_NLS.NLS_ID%TYPE)
    RETURN NUMBER
    IS
    V_NLS M_SYS.M_NLS.NLS_ID%TYPE;
    BEGIN
      INSERT_NLSID(V_NLS,P_DESC,'Y');
    END;



--------------------------------------------------------------------------------------------------------------------------------
end WP_LANGUAGES_CUD;
/

SHOW ERROR

PROMPT Creating Package body 'WP_DISCIPLINES_CUD'

create or replace PACKAGE BODY             "WP_DISCIPLINES_CUD" AS

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
S_DP_ID M_SYS.M_DISCIPLINES.DP_ID%TYPE;
---------------------------------------------------Private Procedures-----------------------------------------------------------    
    PROCEDURE INSERT_DPID(P_DP_CODE     IN M_SYS.M_DISCIPLINES.DP_CODE%TYPE,
                          P_ABBREV      IN M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
        L_COUNT1    PLS_INTEGER;
        V_DISP_ID   NUMBER;
    BEGIN
        --Arrange
        V_DISP_ID := BIR_SPMAT.ADM_P40050.INSERT_DISCIPLINES(NULL,P_NLS_ID,P_DP_CODE,P_ABBREV,P_SHORT_DESC,P_DESC);
        S_DP_ID := V_DISP_ID;
        --Act
        --Get Expected Value
        SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_DISCIPLINES WHERE DP_ID = V_DISP_ID;
        --Assert
        DBMS_OUTPUT.PUT_LINE('Discipline '||P_DP_CODE||' Created');
        UT.EXPECT(L_COUNT1,'NLS ID Not Insertion failed').TO_EQUAL(1);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(100);
    END INSERT_DPID;

--------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE UPDATE_DISP(P_DP_ID       IN M_SYS.M_DISCIPLINES.DP_ID%TYPE,
                          P_DP_CODE     IN M_SYS.M_DISCIPLINES.DP_CODE%TYPE,
                          P_ABBREV      IN M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
        V_DP_ABBREV         M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE;
        V_DP_CODE           M_SYS.M_DISCIPLINES.DP_CODE%TYPE;
        V_SHORT_DESC        M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE;
        V_DESC              M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE;              
    BEGIN
        --Arrange
        --Act
        BIR_SPMAT.ADM_P40050.UPDATE_DISCIPLINES(P_DP_ID,P_NLS_ID,P_DP_CODE,P_ABBREV,P_SHORT_DESC,P_DESC);
        --Get Actual Value
        SELECT 
            DP.DP_CODE, DP.DP_ABBREV,DPN.SHORT_DESC, DPN.DESCRIPTION 
        INTO 
            V_DP_CODE, V_DP_ABBREV, V_SHORT_DESC, V_DESC 
        FROM 
            M_SYS.M_DISCIPLINES DP
        JOIN 
            M_SYS.M_DISCIPLINE_NLS DPN
        ON
            DP.DP_ID = DPN.DP_ID
        WHERE 
            DPN.NLS_ID = P_NLS_ID AND DP.DP_ID = S_DP_ID;
        --Assert
        UT.EXPECT(V_DP_CODE).TO_EQUAL(P_DP_CODE);
        UT.EXPECT(V_DP_ABBREV).TO_EQUAL(P_ABBREV);
        UT.EXPECT(V_SHORT_DESC).TO_EQUAL(P_SHORT_DESC);
        UT.EXPECT(V_DESC).TO_EQUAL(P_DESC);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(100);

    END UPDATE_DISP;
-----------------------------------------Delete Languages from the Table M_NLS--------------------------------------------------
    PROCEDURE DEL_DISP(P_DP_ID IN M_SYS.M_DISCIPLINES.DP_ID%TYPE,
                       P_NLS_ID IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    L_COUNT1    PLS_INTEGER;
    L_COUNT2    PLS_INTEGER;
    L_EXPECTED  SYS_REFCURSOR;
    L_ACTUAL    SYS_REFCURSOR;
BEGIN
    --Arrange
    SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_DISCIPLINES;
    OPEN L_EXPECTED FOR SELECT DP_ID,DP_CODE,DP_ABBREV FROM M_SYS.M_DISCIPLINES;
    --Act
    BIR_SPMAT.ADM_P40050.DELETE_DISCIPLINES(P_DP_ID,P_NLS_ID);
    --Get Actual Value
    OPEN L_ACTUAL FOR SELECT DP_ID,DP_CODE,DP_ABBREV FROM M_SYS.M_DISCIPLINES;
    SELECT COUNT(1) INTO L_COUNT2 FROM M_SYS.M_DISCIPLINES;
    --Assert
    UT.EXPECT(L_EXPECTED).NOT_TO_EQUAL(L_ACTUAL);
    UT.EXPECT(L_COUNT2).NOT_TO_EQUAL(L_COUNT1);

EXCEPTION
        WHEN OTHERS THEN
        UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
END DEL_DISP;
--------------------------------------------------------------------------------------------------------------------------------
    FUNCTION INSERT_DISP (P_DP_CODE      IN M_SYS.M_DISCIPLINES.DP_CODE%TYPE,
                          P_ABBREV      IN M_SYS.M_DISCIPLINES.DP_ABBREV%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE)
    RETURN NUMBER
    IS
    V_DP_ID M_SYS.M_DISCIPLINES.DP_ID%TYPE;
    BEGIN
        V_DP_ID := BIR_SPMAT.ADM_P40050.INSERT_DISCIPLINES(NULL,P_NLS_ID,P_DP_CODE,P_ABBREV,P_SHORT_DESC,P_DESC);
        RETURN V_DP_ID;
    END;

-------------------------------------------------------Public Procedures--------------------------------------------------------

    PROCEDURE DISCIPLINES_SCREEN_WFLOWS
    IS
    V_NLS M_SYS.M_NLS.NLS_ID%TYPE;
    BEGIN
        --Set NLS Value
        V_NLS := WP_LANGUAGES_CUD.GCR_NUMBER;
        --Insert new Discipline
        INSERT_DPID('DISP-'||V_NLS,V_NLS,'PROCUREMENT-'||V_NLS,'PROCUREMENT-'||V_NLS,V_NLS);
        --Update Created Discipline
        --UPDATE_DISP(S_DP_ID,'PROCUREM','PU','PROCURE DEPT','PROCURE DEPARTMENT',V_NLS);
        --Delete Created NLS Language
        --DEL_DISP(S_DP_ID,V_NLS);
    END DISCIPLINES_SCREEN_WFLOWS;
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
end WP_DISCIPLINES_CUD;
/

SHOW ERROR

PROMPT Creating Package body 'WP_USER_GROUPS_CUD'

create or replace PACKAGE body            "WP_USER_GROUPS_CUD" AS

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


    PROCEDURE USERGROUP_SCREEN_WFLOWS
    IS
    UGR_CHECK NUMBER;
    P_UGR_ID M_SYS.M_USER_GROUPS.UGR_ID%TYPE;
    P_NLS    M_SYS.M_NLS.NLS_ID%TYPE;
    L_COUNT NUMBER;
    BEGIN
    SELECT COUNT(*) INTO UGR_CHECK FROM M_SYS.M_USER_GROUPS;
    IF(UGR_CHECK = 0 )THEN
        P_UGR_ID := M_SYS.M_SEQ_UGR_ID.NEXTVAL;
        P_NLS    := WP_LANGUAGES_CUD.GCR_NUMBER;
        INSERT INTO M_SYS.M_USER_GROUPS(UGR_ID, UGR_CODE,LV_ID)
        VALUES(P_UGR_ID,'DEFAULT',NULL);
        INSERT INTO M_SYS.M_USER_GROUP_NLS(UGR_ID,NLS_ID,SHORT_DESC,DESCRIPTION)
        VALUES(P_UGR_ID,P_NLS,'Default User Group','Default User Group');
        P_UGR_CODE := 'DEFAULT';
    ELSE
        SELECT UGR_CODE INTO P_UGR_CODE FROM M_SYS.M_USER_GROUPS WHERE ROWNUM =1; 
    END IF;
    
    SELECT COUNT(*) INTO L_COUNT FROM M_SYS.M_USER_GROUPS;
    --Assert
    DBMS_OUTPUT.PUT_LINE('Usergroup '||P_UGR_CODE||' Selected');
    UT.EXPECT(L_COUNT,'User Groups not Existing').TO_BE_GREATER_THAN(0);
    END;


end WP_USER_GROUPS_CUD;
/

SHOW ERROR

PROMPT Creating Package body 'WP_PROJ_GROUPS_CUD'

create or replace PACKAGE BODY             "WP_PROJ_GROUPS_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Project Groups
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    10-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
S_PGR_ID M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE;
---------------------------------------------------Private Procedures-----------------------------------------------------------    
    PROCEDURE INSERT_PGRID(P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE,
                           P_PGR_CODE    IN M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE,
                           P_SHORT_DESC  IN M_SYS.M_PROJECT_GROUP_NLS.SHORT_DESC%TYPE,
                           P_DESC        IN M_SYS.M_PROJECT_GROUP_NLS.DESCRIPTION%TYPE)
    IS
        L_COUNT1    PLS_INTEGER;
        V_PGR_ID    M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE;
    BEGIN
        --Arrange
        V_PGR_ID := BIR_SPMAT.ADM_P400450.INSERT_PROJECT_GROUP(P_NLS_ID,P_PGR_CODE,P_SHORT_DESC,P_DESC,'NEW PGR GROUP');
        --,'PROJECT_GROUP');
        S_PGR_ID := V_PGR_ID;
        --Act
        --Get Expected Value
        SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_PROJECT_GROUPS WHERE PGR_ID = V_PGR_ID;
        --Assert
        DBMS_OUTPUT.PUT_LINE('Project Group '||P_PGR_CODE||' Created');
        UT.EXPECT(L_COUNT1,'Project Group Insertion failed').TO_EQUAL(1);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
    END INSERT_PGRID;

--------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE UPDATE_PGRP(P_PGR_ID      IN M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE,
                          P_PGR_CODE    IN M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE,
                          P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_PROJECT_GROUP_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_PROJECT_GROUP_NLS.DESCRIPTION%TYPE)
    IS
        V_PGR_CODE          M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE;
        V_SHORT_DESC        M_SYS.M_DISCIPLINE_NLS.SHORT_DESC%TYPE;
        V_DESC              M_SYS.M_DISCIPLINE_NLS.DESCRIPTION%TYPE;              
    BEGIN
        --Arrange
        --Act
        BIR_SPMAT.ADM_P400450.UPDATE_PROJECT_GROUP(P_PGR_ID,P_PGR_CODE,P_NLS_ID,P_SHORT_DESC,P_DESC);
        --Get Actual Value
        SELECT 
            PGR.PGR_CODE, PGRN.SHORT_DESC, PGRN.DESCRIPTION 
        INTO 
            V_PGR_CODE, V_SHORT_DESC, V_DESC 
        FROM 
            M_SYS.M_PROJECT_GROUPS PGR
        JOIN 
            M_SYS.M_PROJECT_GROUP_NLS PGRN
        ON
            PGR.PGR_ID = PGRN.PGR_ID
        WHERE 
            PGRN.NLS_ID = P_NLS_ID AND PGR.PGR_ID = S_PGR_ID;
        --Assert
        UT.EXPECT(V_PGR_CODE).TO_EQUAL(P_PGR_CODE);
        UT.EXPECT(V_SHORT_DESC).TO_EQUAL(P_SHORT_DESC);
        UT.EXPECT(V_DESC).TO_EQUAL(P_DESC);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(100);

    END UPDATE_PGRP;
-----------------------------------------Delete Languages from the Table M_NLS--------------------------------------------------
    PROCEDURE DEL_PGRP(P_PGR_ID      IN M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE,
                       P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    L_COUNT1    PLS_INTEGER;
    L_COUNT2    PLS_INTEGER;
    L_EXPECTED  SYS_REFCURSOR;
    L_ACTUAL    SYS_REFCURSOR;
BEGIN
    --Arrange
    SELECT COUNT(1) INTO L_COUNT1 FROM M_SYS.M_PROJECT_GROUPS;
    OPEN L_EXPECTED FOR SELECT PGR_ID,PGR_CODE FROM M_SYS.M_PROJECT_GROUPS;
    --Act
    BIR_SPMAT.ADM_P400450.DELETE_PROJECT_GROUP(P_PGR_ID,P_NLS_ID,'DEL PROJ GROUP');
    --Get Actual Value
    OPEN L_ACTUAL FOR SELECT PGR_ID,PGR_CODE FROM M_SYS.M_PROJECT_GROUPS;
    SELECT COUNT(1) INTO L_COUNT2 FROM M_SYS.M_PROJECT_GROUPS;
    --Assert
    UT.EXPECT(L_EXPECTED).NOT_TO_EQUAL(L_ACTUAL);
    UT.EXPECT(L_COUNT2).NOT_TO_EQUAL(L_COUNT1);

EXCEPTION
        WHEN OTHERS THEN
        UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
END DEL_PGRP;
--------------------------------------------------------------------------------------------------------------------------------
    FUNCTION INSERT_PGRP (P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE,
                          P_PGR_CODE    IN M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE,
                          P_SHORT_DESC  IN M_SYS.M_PROJECT_GROUP_NLS.SHORT_DESC%TYPE,
                          P_DESC        IN M_SYS.M_PROJECT_GROUP_NLS.DESCRIPTION%TYPE)
    RETURN NUMBER
    IS
    V_PGR_ID    M_SYS.M_PROJECT_GROUPS.PGR_ID%TYPE;
    BEGIN
        V_PGR_ID := BIR_SPMAT.ADM_P400450.INSERT_PROJECT_GROUP(P_NLS_ID,P_PGR_CODE,P_SHORT_DESC,P_DESC,'NEW PGR GROUP');
        RETURN V_PGR_ID;
    END;

-------------------------------------------------------Public Procedures--------------------------------------------------------

    PROCEDURE PROJECT_GROUPS_SCREEN_WFLOWS
    IS
    V_NLS M_SYS.M_NLS.NLS_ID%TYPE;
    BEGIN
        --Set NLS Value
        V_NLS := WP_LANGUAGES_CUD.GCR_NUMBER;
        --Insert new Discipline
        INSERT_PGRID(V_NLS,'PROJGRP-'||V_NLS,'PROJECT-GRP-'||V_NLS,'PROJECT-GRP-'||V_NLS);
        P_PGR_CODE := 'PROJGRP-'||V_NLS;
        --Update Created Discipline
        --UPDATE_PGRP(S_PGR_ID,'OIL PROJ',V_NLS,'OIL AND GAS PROJ','OIL AND GAS PROJECTS');
        --Delete Created NLS Language
        --DEL_PGRP(S_PGR_ID,V_NLS);
    END PROJECT_GROUPS_SCREEN_WFLOWS;
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
end WP_PROJ_GROUPS_CUD;
/

SHOW ERROR

PROMPT Creating Package body 'WP_PROD_GROUPS_CUD'

create or replace PACKAGE BODY             "WP_PROD_GROUPS_CUD" AS

/*
    || *******************************************************************************************
    || Author:  Praveen Kuppili (PK)
    ||
    || Purpose: Workflow package for Create Update and Delete of Project Groups
    ||
    || Change history:
    ||
    || Ver          When           Who          What
    || -------      -----------    ---------    --------------------------------------------------
    || 8.4.0.0-1    10-Jan-2020    PK          Initial version created
    || *******************************************************************************************
*/

--------------------------------------------------------------------------------------------------------------------------------
P_PG_CODE  M_SYS.M_PRODUCT_GROUPS.PG_CODE%TYPE;
---------------------------------------------------Private Procedures-----------------------------------------------------------    
    PROCEDURE INSERT_PGCODE(P_PRODUCT_GROUP  IN M_PRODUCT_GROUPS.PG_CODE%TYPE,
                            P_PG_SHORT_DESC  IN M_PRODUCT_GROUP_NLS.SHORT_DESC%TYPE,
                            P_PG_DESCRIPTION IN M_PRODUCT_GROUP_NLS.DESCRIPTION%TYPE,
                            P_PGR_CODE       IN M_PROJECT_GROUPS.PGR_CODE%TYPE,
                            P_UGR_CODE       IN M_USER_GROUPS.UGR_CODE%TYPE DEFAULT NULL,
                            P_G_NLS_ID       IN M_NLS.NLS_ID%TYPE,
                            P_PLAIN_PASSWD   IN VARCHAR2)
    IS
        L_COUNT     PLS_INTEGER;
        RET_VAL     VARCHAR2(50 CHAR);
    BEGIN
        --Arrange
        RET_VAL := BIR_SPMAT.ADM_P400600.CREATE_PRODUCT_GROUP(P_PRODUCT_GROUP,P_PG_SHORT_DESC,P_PG_DESCRIPTION,P_PGR_CODE,P_UGR_CODE,P_PLAIN_PASSWD);
        --,'PROJECT_GROUP');
        --Act
        --Get Expected Value
        SELECT COUNT(1) INTO L_COUNT FROM M_SYS.M_PRODUCT_GROUPS WHERE PG_CODE = P_PG_CODE;
        --Assert
        DBMS_OUTPUT.PUT_LINE('Product Group '||P_PRODUCT_GROUP||' Created');
        UT.EXPECT(L_COUNT,'Product Group Insertion failed').TO_EQUAL(1);

    EXCEPTION
        WHEN OTHERS THEN
            UT.EXPECT(SQLCODE).TO_EQUAL(-20000);
    END INSERT_PGCODE;

--------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------Public Procedures--------------------------------------------------------

    PROCEDURE PRODUCT_GROUP_SCREEN_WFLOWS
    IS
    V_NLS M_SYS.M_NLS.NLS_ID%TYPE;
    P_PGR_CODE M_SYS.M_PROJECT_GROUPS.PGR_CODE%TYPE;
    P_UGR_CODE M_SYS.M_USER_GROUPS.UGR_CODE%TYPE;
    BEGIN
        --Set NLS Value
        V_NLS := WP_LANGUAGES_CUD.GCR_NUMBER;
        P_PGR_CODE := WP_PROJ_GROUPS_CUD.P_PGR_CODE;
        P_UGR_CODE := WP_USER_GROUPS_CUD.P_UGR_CODE;
        --Insert new Discipline
        INSERT_PGCODE('PGCODE-'||V_NLS,'POWER_PROJ-'||V_NLS,'POWER PROJECTS-'||V_NLS,P_PGR_CODE,P_UGR_CODE,V_NLS,'PRODUCTGROUP');
        P_PG_CODE := 'PGCODE-'||V_NLS;
        --Update Created Discipline
        --UPDATE_PGRP(S_PGR_ID,'OIL PROJ',V_NLS,'OIL AND GAS PROJ','OIL AND GAS PROJECTS');
        --Delete Created NLS Language
        --DEL_PGRP(S_PGR_ID,V_NLS);
    END PRODUCT_GROUP_SCREEN_WFLOWS;
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
end WP_PROD_GROUPS_CUD;
/

SHOW ERROR

PROMPT Creating Package body 'WT_MAT_ADM1'

create or replace PACKAGE BODY             "WT_MAT_ADM1" AS

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

--%suite(Workflows for Smart Materials)
--%suitepath(WF_ADMIN_APEX)
--%rollback(manual)

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------
    PROCEDURE LOGIN_WF
    IS
    BEGIN
        WP_LOGIN.CREATE_SESSION(101,1);
    END;

    PROCEDURE LANGAUGES_WF
    IS
    BEGIN
        WP_LANGUAGES_CUD.LANGUAGE_SCREEN_WFLOWS;
    END;

    PROCEDURE DISCIPLINES_WF
    IS
    BEGIN
        WP_DISCIPLINES_CUD.DISCIPLINES_SCREEN_WFLOWS;
    END;

    PROCEDURE PROJECT_GROUPS_WF
    IS
    BEGIN
        WP_PROJ_GROUPS_CUD.PROJECT_GROUPS_SCREEN_WFLOWS;
    END;
    
    PROCEDURE USERGROUP_SCREEN_WF
    IS
    BEGIN
        WP_USER_GROUPS_CUD.USERGROUP_SCREEN_WFLOWS;
    END;
    
    PROCEDURE PRODUCT_GROUPS_WF
    IS
    BEGIN
        WP_PROD_GROUPS_CUD.PRODUCT_GROUP_SCREEN_WFLOWS;
    END;


end WT_MAT_ADM1;
/

SHOW ERROR

PROMPT Creating Package body 'WP_USERS_CUD'

create or replace PACKAGE BODY             "WP_USERS_CUD" 
IS

G_NLS_ID M_SYS.M_NLS.NLS_ID%TYPE := WP_LANGUAGES_CUD.GCR_NUMBER;
G_USR_ID M_SYS.M_USER_SECURITIES.M_USR_ID%TYPE := WP_LOGIN.G_USR_ID;
G_PROJ_ID M_SYS.M_PROJECTS.PROJ_ID%TYPE := WP_LOGIN.G_PROJ_ID;
G_DP_ID M_SYS.M_DISCIPLINES.DP_ID%TYPE := WP_LOGIN.G_DP_ID;
G_ROLE_ID M_SYS.M_APPL_ROLES.ROLE_ID%TYPE := WP_LOGIN.G_ROLE_ID;

PROCEDURE INSERT_USER(P_USR_ID      IN M_SYS.M_USERS.M_USR_ID%TYPE,
                      P_UGR_CODE    IN M_SYS.M_USER_GROUPS.UGR_CODE%TYPE,
                      P_PASSWORD    IN VARCHAR2,
                      P_FIRST_NAME  IN M_SYS.M_USERS.FIRST_NAME%TYPE,
                      P_LAST_NAME   IN M_SYS.M_USERS.LAST_NAME%TYPE,
                      P_COMPANY     IN M_SYS.M_USERS.COMPANY%TYPE,
                      P_DEPARTMENT  IN M_SYS.M_USERS.DEPARTMENT%TYPE,
                      P_TELEPHONE   IN M_SYS.M_USERS.TELEPHONE%TYPE,
                      P_FAX         IN M_SYS.M_USERS.FAX%TYPE,
                      P_EMAIL       IN M_SYS.M_USERS.EMAIL%TYPE,
                      P_PW_INTERVAL IN M_SYS.M_USERS.PW_CHANGE_DAYS%TYPE,
                      P_PW_HISTCHNG IN M_SYS.M_USERS.PW_HISTORY%TYPE,
                      P_PWD_VIAMAIL IN M_SYS.M_PVMSQS.PVM%TYPE,
                      P_ALLOWEDAMNT IN M_SYS.M_USERS.AMOUNT%TYPE,
                      P_CURNCY_ID   IN M_SYS.M_USERS.CURRENCY_ID%TYPE,
                      P_GLOBALACCES IN M_SYS.M_USERS.SUPER_USER_IND%TYPE,
                      P_CURRENCY    IN VARCHAR2
                      )
AS
RET_USER    VARCHAR2(25 CHAR);
L_ACTUAL   VARCHAR2(30 CHAR);
L_EXPECTED  VARCHAR2(30 CHAR);

BEGIN
    --Arrange
    APEX_UTIL.SET_SESSION_STATE('F101_PAGE_NLS',G_NLS_ID);
    APEX_UTIL.SET_SESSION_STATE('P400160_PASSWORD',P_PASSWORD);
    APEX_UTIL.SET_SESSION_STATE('P400160_FIRST_NAME',P_FIRST_NAME);
    APEX_UTIL.SET_SESSION_STATE('P400160_LAST_NAME',P_LAST_NAME);
    APEX_UTIL.SET_SESSION_STATE('P400160_COMPANY',P_COMPANY );
    APEX_UTIL.SET_SESSION_STATE('P400160_DEPARTMENT',P_DEPARTMENT);
    APEX_UTIL.SET_SESSION_STATE('P400160_TELEPHONE',P_TELEPHONE);
    APEX_UTIL.SET_SESSION_STATE('P400160_FAX',P_FAX);
    APEX_UTIL.SET_SESSION_STATE('P400160_EMAIL',P_EMAIL);
    APEX_UTIL.SET_SESSION_STATE('P400160_PW_INTERVAL',P_PW_INTERVAL);
    APEX_UTIL.SET_SESSION_STATE('P400160_PW_HISTORY_CHANGE',P_PW_HISTCHNG);
    APEX_UTIL.SET_SESSION_STATE('P400160_PASSWORD_VIA_EMAIL',P_PWD_VIAMAIL);
    APEX_UTIL.SET_SESSION_STATE('P400160_ALLOWED_AMOUNT',P_ALLOWEDAMNT);
    APEX_UTIL.SET_SESSION_STATE('P400160_CURRENCY_ID',P_CURNCY_ID);
    APEX_UTIL.SET_SESSION_STATE('P400160_GLOBAL_ACCESS',P_GLOBALACCES);
    APEX_UTIL.SET_SESSION_STATE('P400160_PT5226USERGROUP','User Group');
    APEX_UTIL.SET_SESSION_STATE('P400160_CURRENCY',P_CURRENCY);

    --Act
    RET_USER := ADM_P400160.CREATE_USER(P_USR_ID,P_UGR_CODE ,'N','N');
    
    L_EXPECTED := P_USR_ID;

    SELECT M_USR_ID INTO L_ACTUAL FROM M_SYS.M_USERS WHERE M_USR_ID = P_USR_ID;

    --dbms_output.put_line('considered test case user_id:'|| P_usr_id );

    --dbms_output.put_line('expected value: ' ||  l_expected);
    
    --Assert
    DBMS_OUTPUT.PUT_LINE('User '||P_USR_ID||' Created');
    UT.EXPECT(L_ACTUAL).TO_EQUAL(L_EXPECTED);

 END INSERT_USER;
 
PROCEDURE USER_SCREEN_WORKFLOWS
IS
V_NLS      M_SYS.M_NLS.NLS_ID%TYPE := WP_LANGUAGES_CUD.GCR_NUMBER;
V_UGR_CODE VARCHAR2(255) := WP_USER_GROUPS_CUD.P_UGR_CODE;
BEGIN
INSERT_USER(P_USR_ID        => 'ADMIN-'||V_NLS,
            P_UGR_CODE      => V_UGR_CODE,
            P_PASSWORD      => 'Admin@123',
            P_FIRST_NAME    => 'ADMINISTRATOR',
            P_LAST_NAME     => 'SMAT',
            P_COMPANY       => 'PKK COMPANIES PVT LTD',
            P_DEPARTMENT    => 'PPM DEPT',
            P_TELEPHONE     => '4587562352',
            P_FAX           => '',
            P_EMAIL         => 'PRAVEENKUMAR.KUPPILI@HEXAGON.COM',
            P_PW_INTERVAL   => '',
            P_PW_HISTCHNG   => '',
            P_PWD_VIAMAIL   => 'N',
            P_ALLOWEDAMNT   => '',
            P_CURNCY_ID     => '',
            P_GLOBALACCES   => 'N',
            P_CURRENCY      => 'USD'
           );
END;


END WP_USERS_CUD;
/

SHOW ERROR

PROMPT Creating Package Body 'WP_ROLES_CUD'

create or replace PACKAGE BODY             "WP_ROLES_CUD" IS

GC_ROLE_ID M_SYS.M_APPL_ROLES.ROLE_ID%TYPE;

   PROCEDURE INSERT_ROLES(P_NLS_ID      IN M_SYS.M_NLS.NLS_ID%TYPE,
                          P_ROLE_NAME   IN M_SYS.M_APPL_ROLES.ROLE_NAME%TYPE,
                          P_DESCRIPTION IN M_SYS.M_APPL_ROLE_NLS.DESCRIPTION%TYPE,
                          P_PROMPT_ROLE VARCHAR2)
    IS    
    L_ACTUAL_NLS_ID       M_SYS.M_NLS.NLS_ID%TYPE;
    L_ACTUAL_ROLE_NAME    M_SYS.M_APPL_ROLES.ROLE_NAME%TYPE;
    L_ACTUAL_DESCRIPTION  M_SYS.M_APPL_ROLE_NLS.DESCRIPTION%TYPE;
    L_ACTUAL_PROMPT_ROLE  VARCHAR2(255);

    BEGIN
      --Act
      GC_ROLE_ID:=ADM_P400820.INSERT_ROLES(P_NLS_ID, P_ROLE_NAME, P_DESCRIPTION, P_PROMPT_ROLE);

      -- Get Actuals

      SELECT NLS_ID      INTO L_ACTUAL_NLS_ID      FROM  M_SYS.M_APPL_ROLE_NLS WHERE ROLE_ID=GC_ROLE_ID;
      SELECT ROLE_NAME   INTO L_ACTUAL_ROLE_NAME   FROM  M_SYS.M_APPL_ROLES    WHERE ROLE_ID=GC_ROLE_ID;
      SELECT DESCRIPTION INTO L_ACTUAL_DESCRIPTION FROM  M_SYS.M_APPL_ROLE_NLS WHERE ROLE_ID=GC_ROLE_ID;

      -- Assert
      DBMS_OUTPUT.PUT_LINE('Role '||P_ROLE_NAME||' Created');
      UT.EXPECT(L_ACTUAL_NLS_ID).TO_EQUAL(P_NLS_ID);
      UT.EXPECT(L_ACTUAL_ROLE_NAME).TO_EQUAL(P_ROLE_NAME);
      UT.EXPECT(L_ACTUAL_DESCRIPTION).TO_EQUAL(P_DESCRIPTION);
      
   END INSERT_ROLES;

   PROCEDURE ASSIGN_SINGLE_MENU(P_ROLE_ID              IN M_SYS.M_APPL_ROLES_MENUS.ROLE_ID%TYPE,
                                P_MENUITEM_CODE        IN M_SYS.M_APPL_MENUS.MENUITEM_CODE%TYPE,
                                P_QUERY_ONLY_IND       IN M_SYS.M_APPL_ROLES_MENUS.QUERY_ONLY_IND%TYPE,
                                P_DEACT_IND            IN M_SYS.M_APPL_ROLES_MENUS.DEACT_IND%TYPE ,
                                P_NO_CONFIG_CHANGE_IND IN M_SYS.M_APPL_ROLES_MENUS.NO_CONFIG_CHANGE_IND%TYPE ,
                                P_PROMPT_MENU          IN VARCHAR2,
                                P_NLS_ID               IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    RETURN_ROWID VARCHAR2(50 CHAR);
    BEGIN
    RETURN_ROWID := ADM_P400820.INSERT_ROLES_MENUS(P_ROLE_ID,P_MENUITEM_CODE,P_QUERY_ONLY_IND,P_DEACT_IND,
                                       P_NO_CONFIG_CHANGE_IND,P_PROMPT_MENU,P_NLS_ID);
    
    --UT.EXPECT(RETURN_ROWID).TO_BE_NOT_NULL;
    
    END ASSIGN_SINGLE_MENU;
    
    
    PROCEDURE ASSIGN_MENUS(P_ROLE_ID IN M_SYS.M_APPL_ROLES_MENUS.ROLE_ID%TYPE,
                           P_NLS_ID               IN M_SYS.M_NLS.NLS_ID%TYPE)
    IS
    L_EXPECTED NUMBER;
    L_ACTUAL   NUMBER;
    P_ROLE_NAME  M_SYS.M_APPL_ROLES.ROLE_NAME%TYPE;
    CURSOR T_CURSOR IS SELECT MENUITEM_CODE FROM M_SYS.M_APPL_MENUS WHERE MENU_TYPE='BI_REPORT';
    BEGIN
    SELECT ROLE_NAME   INTO P_ROLE_NAME FROM  M_SYS.M_APPL_ROLES    WHERE ROLE_ID=GC_ROLE_ID;
    SELECT COUNT(*) INTO L_EXPECTED FROM M_APPL_MENUS WHERE MENU_TYPE='BI_REPORT';
    --DBMS_OUTPUT.PUT_LINE(L_EXPECTED||' no of Menus');
    
    FOR EACHMENU IN T_CURSOR 
    LOOP
    ASSIGN_SINGLE_MENU(P_ROLE_ID,EACHMENU.MENUITEM_CODE,'N','N','N',EACHMENU.MENUITEM_CODE,P_NLS_ID);
    END LOOP;
    
    SELECT COUNT(*) INTO L_ACTUAL FROM M_APPL_ROLES_MENUS WHERE ROLE_ID = P_ROLE_ID;
    DBMS_OUTPUT.PUT_LINE('Role '||P_ROLE_NAME||' Is Assigned with '||L_ACTUAL||' no of Menus');
    UT.EXPECT(L_EXPECTED).TO_EQUAL(L_ACTUAL);
    
    END;
    
   
  /* -- test insert_roles_menus case 1: ...
   --
   PROCEDURE ut_insert_roles_menus IS
        l_from_role_id             m_sys.m_appl_roles_menus.role_id%TYPE                :=5140;  --Super User Role ID

   BEGIN
      -- populate actual
      adm_p400822.copy_role_data(l_from_role_id, g_role_id);

   END ut_insert_roles_menus;*/

   PROCEDURE ROLES_SCREEN_WORKFLOWS
   IS
   V_NLS      M_SYS.M_NLS.NLS_ID%TYPE := WP_LANGUAGES_CUD.GCR_NUMBER;
   BEGIN
   --Arrange
   --Add New Role
   INSERT_ROLES(V_NLS,'ROLE-'||V_NLS, 'NEWROLE-'||V_NLS,'ROLE NAME');
   
   END;
   
   PROCEDURE ROLES_SCREEN_WORKFLOWS1
   IS
   V_NLS      M_SYS.M_NLS.NLS_ID%TYPE := WP_LANGUAGES_CUD.GCR_NUMBER;
   BEGIN
   --Arrange
   --Add Menus to Roles
   ASSIGN_MENUS(GC_ROLE_ID,V_NLS);
   
   END;

END WP_ROLES_CUD;
/
SHOW ERROR 

PROMPT Creating Package body 'WT_MAT_ADM2'

create or replace PACKAGE BODY             "WT_MAT_ADM2" AS

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

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------Public Procedures--------------------------------------------------------
     PROCEDURE LOGIN_WF
    IS
    BEGIN
        WP_LOGIN.CREATE_SESSION(400,1);
    END;

    PROCEDURE USERS_WF
    IS
    BEGIN
        WP_USERS_CUD.USER_SCREEN_WORKFLOWS;
    END;
	
	PROCEDURE ROLES_WF
    IS
    BEGIN
        WP_ROLES_CUD.ROLES_SCREEN_WORKFLOWS;
    END;

    PROCEDURE MAP_MENUS_TO_ROLES_WF
    IS
    BEGIN
        WP_ROLES_CUD.ROLES_SCREEN_WORKFLOWS1;
    END;




end WT_MAT_ADM2;
/
