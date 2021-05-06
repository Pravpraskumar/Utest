<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   <xsl:template match="/">
      <html>
         <body>
			<style>
				.head{
					    font-size: 2.0em;
						font-family: monospace;
						text-decoration: underline;
						width: 800px;
						text-align: center;
						max-width:800px;
						}
				.stat-Failure, .trfail{
					background-color: darksalmon;
					}
				.cont0, .cont1, .cont2{
						width: 800px;
						}
				.cont0 td, .cont1 .cent, .cont2 .cent{
					text-align: center;
					}
				.stat-Error{
					background: darkkhaki;
					}
				.trnorm, .stat-{
				    background: lightgreen;
					}
			</style>
            <div class="head">Unit Test Workflow Results</div>
			<table border="1" class="cont0">
               <tr>
                  <th>Total Tests</th>
				  <th>Disabled</th>
                  <th>Errors</th>
                  <th>Failures</th>
				  <th>Total Time</th>
               </tr>
               <xsl:for-each select="testsuites">
                  <tr>
                     <td>
                        <xsl:value-of select="@tests" />
                     </td>
					 <td>
                        <xsl:value-of select="@disabled" />
                     </td>
                     <td>
                        <xsl:value-of select="@errors" />
                     </td>
                     <td>
                        <xsl:value-of select="@failures" />
                     </td>
					 <td>
                        <xsl:value-of select="@time" />
                     </td>
                  </tr>
               </xsl:for-each>
            </table>
			<br></br>
			<br></br>
            <table border="1" class="cont1">
               <tr>
				  <th>Workflow Name</th>
                  <th>Total Tests</th>
				  <th>Disabled</th>
                  <th>Errors</th>
                  <th>Failures</th>
				  <th>Total Time</th>
               </tr>
               <xsl:for-each select="testsuites/testsuite/testsuite">
                  <tr>
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="@failures = '0'">trnorm</xsl:when>
							<xsl:otherwise>trfail</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					 <td>
                        <xsl:value-of select="@name" />
                     </td>
                     <td class="cent">
                        <xsl:value-of select="@tests" />
                     </td>
					 <td class="cent">
                        <xsl:value-of select="@disabled" />
                     </td>
                     <td class="cent">
                        <xsl:value-of select="@errors" />
                     </td>
                     <td class="cent">
                        <xsl:value-of select="@failures" />
                     </td>
					 <td class="cent">
                        <xsl:value-of select="@time" />
                     </td>
                  </tr>
               </xsl:for-each>
            </table>
			<br></br>
			<br></br>
			<table border="1" class="cont2">
               <tr>
				  <th>Workflow Name</th>
                  <th>Test case Name</th>
				  <th>No of Assertions</th>
                  <th>Time Taken</th>
				  <th>Status</th>
				  <th>Result</th>
               </tr>
               <xsl:for-each select="testsuites/testsuite/testsuite/testcase">
                  <tr class="stat-{@status}">
					 <td>
						<xsl:value-of select="../@name" />
					 </td>
                     <td>
                        <xsl:value-of select="@name" />
                     </td>
					 <td class="cent">
                        <xsl:value-of select="@assertions" />
                     </td>
                     <td class="cent">
                        <xsl:value-of select="@time" />
                     </td>
					 <td class="cent">
						<xsl:choose>
						<xsl:when test="@status = 'Failure'">
							<xsl:value-of select="'Fail'" />
						</xsl:when>
						<xsl:when test="@status = 'Error'">
							<xsl:value-of select="'Error'" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'Pass'" />
						</xsl:otherwise>
					</xsl:choose>
                     </td>
					<td>
                        <xsl:value-of select="system-out" />
                     </td>
                  </tr>
               </xsl:for-each>
            </table>
         </body>
      </html>
   </xsl:template>
</xsl:stylesheet>
