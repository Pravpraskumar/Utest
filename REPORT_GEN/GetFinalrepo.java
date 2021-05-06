import java.io.*; 
import java.text.*;
public class GetFinalrepo {
     public static void main(String args[]) throws IOException {
				String DBSbld=args[0];
				String BIRbld=args[1];
				
				
                PrintWriter pw = new PrintWriter(new FileWriter("./FinalRepo.html"));
                pw.println("<html>");
		pw.println("<body>");
		pw.println("<TABLE BORDER=1><TR style=\"height:30px; background:bisque; color:blue; \"><TD style=\"padding: 10px;\"> DB Setup <TD style=\"padding: 10px;\">"+DBSbld+"</TR>");
        pw.println("<TR style=\"height: 30px;background:bisque; color:blue;\"><TD style=\"padding: 10px;\"> BIR Setup <TD style=\"padding: 10px;\">"+ BIRbld+"</TR>");
        pw.println("</TABLE>");
		pw.println("</br>");
		pw.println("</br>");
		pw.println("</body>");
		pw.println("</html>");
		
		BufferedReader br = new BufferedReader(new FileReader("./report.html"));
		String line = br.readLine();
		
		while (line != null)
		{
			pw.println(line);
			line = br.readLine();
		}
		
		pw.flush();
		
		//closing resources
		br.close();
		pw.close();
		
    }
}
