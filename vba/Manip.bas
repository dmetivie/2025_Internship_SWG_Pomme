Attribute VB_Name = "Manip"
Option Explicit
Option Base 1

' Manipulation de données au sein du fichier (en dehors de la modélisation) :
' importation des données et exportation des résultats
' feuilles utilisées : "Model", "Out", "Min", Moy", Max", "Pollen"

Public Const firstDateRow As Integer = 16  ' Première ligne des données de date
Public Const firstObsCol As Integer = 8    ' Première colonne des données observées
Public Const firstPrevCol As Integer = 17    ' Première colonne des prévisions

Public Sub ClearData()
InterfaceOption
    Application.Calculation = xlCalculationManual
    Sheets("Min").Range("B1:BZ505").ClearContents
    Sheets("Moy").Range("B1:BZ505").ClearContents
    Sheets("Max").Range("B1:BZ505").ClearContents
    Sheets("Pollen").Range("B1:BZ505").ClearContents
    Sheets("View").Range("B2:H505").ClearContents
    FormatYearObs (1)
    Sheets("Model").Range("Taxon").value = "Pas de données"
    Application.Calculation = xlCalculationAutomatic
End Sub

Public Sub ImportFile()
InterfaceOption
' Copie les feuilles "Min", "Moy", "Max" et "Pollen" depuis un fichier
' (en adaptant le format de l'application)
' Contraintes sur le fichier d'entrée :
'    - les 4 feuilles de données doivent être nommées "Min", "Moy", "Max" et "Pollen"
'    - elle ont le même nombre de colonnes (<75)
'    - les données commencent au 01/01
    Dim yr As String
    Dim fileN As String
    Dim j As Integer
    Dim n As Integer
    Dim col As Integer
    Dim srcWB As Workbook
    Dim polSht As String
    Dim minSht As String
    Dim moySht As String
    Dim maxSht As String
    Dim J0 As Date
    Application.Calculation = xlCalculationManual
On Error GoTo END_ERR
    ' Vérification des données du fichier source
    fileN = Application.GetOpenFilename()
    If UCase(fileN) = "FAUX" Or UCase(fileN) = "FALSE" Then GoTo END_SUB
    Workbooks.Open fileN
    polSht = "Pollen"
On Error GoTo ERR_POL
    Sheets(polSht).Select
On Error GoTo END_ERR
    Set srcWB = ActiveWorkbook
    col = 1
    Do: col = col + 1
    Loop Until Sheets(polSht).Cells(1, col).value = ""
    n = col
    col = 1
    minSht = "Min"
On Error GoTo ERR_MIN
    Sheets(minSht).Select
On Error GoTo END_ERR
    Do: col = col + 1
    Loop Until Sheets(minSht).Cells(1, col).value = ""
    If col <> n Then msgbox "Les données de température min n'ont pas le même " _
                   & vbCr & "nombre de colonnes que les données pollen !"
    moySht = "Moy"
On Error GoTo ERR_MOY
    Sheets(moySht).Select
On Error GoTo END_ERR
    col = 1
    Do: col = col + 1
    Loop Until Sheets(moySht).Cells(1, col).value = ""
    If col <> n Then msgbox "Les données de température moy n'ont pas le même " _
                   & vbCr & "nombre de colonnes que les données pollen !"
    maxSht = "Max"
On Error GoTo ERR_MAX
    Sheets(maxSht).Select
On Error GoTo END_ERR
    col = 1
    Do: col = col + 1
    Loop Until Sheets(maxSht).Cells(1, col).value = ""
    If col <> n Then msgbox "Les données de température max n'ont pas le même " _
                   & vbCr & "nombre de colonnes que les données pollen !"
    n = n - 2
    With ThisWorkbook
    ' Nettoyage de la feuille de destination
    .Sheets("Min").Range("B1:DZ505").ClearContents
    .Sheets("Moy").Range("B1:DZ505").ClearContents
    .Sheets("Max").Range("B1:DZ505").ClearContents
    .Sheets("Pollen").Range("B1:DZ505").ClearContents
    ' Copie des entêtes
    For col = 2 To n + 1
        yr = srcWB.Sheets(polSht).Cells(1, col).value
        .Sheets("Min").Cells(1, col).value = yr
        .Sheets("Moy").Cells(1, col).value = yr
        .Sheets("Max").Cells(1, col).value = yr
        .Sheets("Pollen").Cells(1, col).value = yr
    Next
    J0 = srcWB.Sheets(polSht).Range("A2").value
    If Month(J0) = 8 And day(J0) = 15 Then   ' Données depuis le 15/08
        ' Copie des données du 15/08 au 31/12
        .Sheets("Min").Range("B2:DZ505").value = srcWB.Sheets(minSht).Range("B2:DZ505").value
        .Sheets("Moy").Range("B2:DZ505").value = srcWB.Sheets(moySht).Range("B2:DZ505").value
        .Sheets("Max").Range("B2:DZ505").value = srcWB.Sheets(maxSht).Range("B2:DZ505").value
        .Sheets("Pollen").Range("B2:DZ505").value = srcWB.Sheets(polSht).Range("B2:DZ505").value
        .Sheets("Model").Range("Taxon").value = srcWB.Name
        srcWB.Close
        ' Initialisation des données
        FormatYearObs n
        If msgbox("Voulez-vous vérifier les données ? ", vbYesNo) = vbYes _
        Then CheckData
        ImportDates
    Else  ' Date de début de données non valide
        msgbox "Les séries de données doivent commencer au 15/08 !" & vbCr & _
               "L'importation a échoué. Modifiez le fichier et recommencez."
    End If
    End With    ' Thisworkbook
    GoTo END_SUB
ERR_POL: polSht = InputBox("Nom de la feuille de pollen ?", , "Pollen")
         Resume
ERR_MIN: minSht = InputBox("Nom de la feuille de t° min ?", , "Min")
         Resume
ERR_MOY: moySht = InputBox("Nom de la feuille de t° moy ?", , "Moy")
         Resume
ERR_MAX: maxSht = InputBox("Nom de la feuille de t° max ?", , "Max")
         Resume
END_ERR:    col = col
            msgbox "Echec de la macro ImportFile !"
END_SUB: Application.Calculation = xlCalculationAutomatic
End Sub
Private Sub CheckData()
    Dim rw As Integer
    Dim col As Integer
    Dim nDM As Integer
    Dim nNN As Integer
    Sheets("Pollen").Select
    For rw = 2 To 505
        col = 2
        Do Until Cells(1, col).value = ""
            If Not IsNumeric(Cells(rw, col).value) Then
                Cells(rw, col).Select
                msgbox "Donnée non numérique : ligne " & rw & " colonne " & col
                nNN = nNN + 1
            End If
            col = col + 1
        Loop
    Next
    Sheets("Min").Select
    For rw = 2 To 505
        col = 2
        Do Until Cells(1, col).value = ""
            If Cells(rw, col).value = "" Then
                Cells(rw, col).Select
                msgbox "Donnée manquante : ligne " & rw & " colonne " & col
                nDM = nDM + 1
            Else
                If Not IsNumeric(Cells(rw, col).value) Then
                    Cells(rw, col).Select
                    msgbox "Donnée non numérique : ligne " & rw & " colonne " & col
                    nNN = nNN + 1
                End If
            End If
            col = col + 1
        Loop
    Next
    Sheets("Moy").Select
    For rw = 2 To 505
        col = 2
        Do Until Cells(1, col).value = ""
            If Cells(rw, col).value = "" Then
                Cells(rw, col).Select
                msgbox "Donnée manquante : ligne " & rw & " colonne " & col
                nDM = nDM + 1
            Else
                If Not IsNumeric(Cells(rw, col).value) Then
                    Cells(rw, col).Select
                    msgbox "Donnée non numérique : ligne " & rw & " colonne " & col
                    nNN = nNN + 1
                End If
            End If
            col = col + 1
        Loop
    Next
    Sheets("Max").Select
    For rw = 2 To 505
        col = 2
        Do Until Cells(1, col).value = ""
            If Cells(rw, col).value = "" Then
                Cells(rw, col).Select
                msgbox "Donnée manquante : ligne " & rw & " colonne " & col
                nDM = nDM + 1
            Else
                If Not IsNumeric(Cells(rw, col).value) Then
                    Cells(rw, col).Select
                    msgbox "Donnée non numérique : ligne " & rw & " colonne " & col
                    nNN = nNN + 1
                End If
            End If
            col = col + 1
        Loop
    Next
    Sheets("Model").Select
    msgbox nDM & " données manquantes détectées !" & vbCr & nNN & " données non numériques détectées !"
End Sub

Public Sub ImportDates()
InterfaceOption
' Calcule les dates-clés à partir de la feuille "Pollen" et les écrit dans la feuille "Model"
    Dim yr As Integer
    Dim i As Integer
    Dim j As Integer
    Dim n As Integer
    Dim M As Integer
    Dim cum As Double
    Dim sum As Double
    Dim dat() As Double
    Dim keys(1 To 6) As Double
    Dim datMoy(1 To 6) As Double
    Application.Calculation = xlCalculationManual
    n = Sheets("Model").Range("ObsYearNb").value
    ReDim dat(1 To n, 1 To 6)
    keys(1) = 0.05: keys(2) = 0.1: keys(3) = 0.25
    keys(4) = 0.5: keys(5) = 0.75: keys(6) = 0.9
    For yr = 1 To n
        sum = 0
        For j = 1 To nDays
            sum = sum + Sheets("Pollen").Cells(1 + j, 1 + yr).value
        Next
        If sum > 0 Then
            j = 0: cum = 0
            For i = 1 To 6
                Do Until cum / sum > keys(i) Or j > nDays
                    j = j + 1
                    cum = cum + Sheets("Pollen").Cells(1 + j, 1 + yr).value
                Loop
                dat(yr, i) = j - dayOffset
            Next
        End If
    Next
    For i = 1 To 6
        sum = 0: M = 0
        For yr = 1 To n
            If dat(yr, i) > 0 Then
                M = M + 1
                sum = sum + dat(yr, i)
            End If
        Next
        If M > 0 Then datMoy(i) = sum / M
    Next
    For yr = 1 To n
        Sheets("Model").Cells(firstDateRow + yr - 1, firstObsCol - 2).value = Sheets("Pollen").Cells(1, 1 + yr).value
    Next
    For i = 1 To 6
        For yr = 1 To n
            If dat(yr, i) > 0 Then _
            Sheets("Model").Cells(firstDateRow + yr - 1, firstObsCol + i - 1).value = dat(yr, i)
            Sheets("Model").Cells(firstDateRow + yr - 1, firstPrevCol + i - 1).value = datMoy(i)
        Next
    Next
    Application.Calculation = xlCalculationAutomatic
    ScaleGraph
End Sub

Public Sub FormatYearObs(Optional n As Integer = 0)
InterfaceOption
' Formate le fichier pour avoir n années d'observation
    Dim i As Integer
    Dim j As Integer
    On Error GoTo END_SUB
    Sheets("Model").Select
    If n = 0 Then n = InputBox("Combien d'années de données ?", , Range("obsYearNb").value)
    Range("obsYearNb").value = n
    Range(Cells(firstDateRow, firstObsCol), Cells(firstDateRow + 99, firstObsCol + 5)).ClearContents
    Range(Cells(firstDateRow, firstPrevCol), Cells(firstDateRow + 99, firstPrevCol + 5)).ClearContents
    Range(Cells(firstDateRow, firstPrevCol - 2), Cells(firstDateRow + 99, firstPrevCol - 2)).ClearContents
    For i = 0 To n - 1
        Cells(firstDateRow + i, firstObsCol - 2).value = "An " & i
    Next
    For i = n To 99
        Cells(firstDateRow + i, firstObsCol - 2).value = ""
    Next
END_SUB:
End Sub

Public Sub ResultsOut()
InterfaceOption
' Exporte les résultats courrants de "Model" dans la feuille "Out"
    Dim i As Integer
    Dim k As Integer
    Dim np As Integer
    Do: i = i + 1
    Loop Until Sheets("Out").Cells(i, 1).value = ""
    Sheets("Out").Cells(i, 1).value = Date
    Sheets("Out").Cells(i, 2).value = Time
    Sheets("Out").Cells(i, 3).value = Sheets("Model").Range("Taxon").value
    Sheets("Out").Cells(i, 4).value = Sheets("Model").Range("ObsYearNb").value
    Sheets("Out").Cells(i, 5).value = Sheets("Model").Range("NbPara").value
    Sheets("Out").Cells(i, 6).value = Sheets("Model").Range("Comments").value
    Sheets("Out").Cells(i, 7).value = Sheets("Model").Range("GlobalR2").value
    If Sheets("Model").Range("ChilOpt").value Then  'Vernalisation active
        Sheets("Out").Cells(i, 8).value = ModelString(Sheets("Model").Range("ChilMdlNb").value)
        Sheets("Out").Cells(i, 9).value = TempString(Sheets("Model").Range("ChilTemp").value)
        Sheets("Out").Cells(i, 10).value = Sheets("Model").Range("ChilJED").value
        Sheets("Out").Cells(i, 11).value = Sheets("Model").Range("ChilTc").value
        If Sheets("Model").Range("ChilMdlNb").value > 2 Then _
            Sheets("Out").Cells(i, 12).value = Sheets("Model").Range("ChilEc").value
        Sheets("Out").Cells(i, 13).value = Sheets("Model").Range("ChilCx").value
    Else
        Sheets("Out").Cells(i, 16).value = Sheets("Model").Range("ForcJLD").value
    End If
    Sheets("Out").Cells(i, 14).value = ModelString(Sheets("Model").Range("ForcMdlNb").value)
    Sheets("Out").Cells(i, 15).value = TempString(Sheets("Model").Range("ForcTemp").value)
    Sheets("Out").Cells(i, 17).value = Sheets("Model").Range("ForcTf").value
    If Sheets("Model").Range("ForcMdlNb").value > 2 Then _
        Sheets("Out").Cells(i, 18).value = Sheets("Model").Range("ForcEf").value
    For k = 1 To 6
        Sheets("Out").Cells(i, 18 + k).value = Sheets("Model").Cells(firstDateRow - 2, firstPrevCol + k - 1).value
        Sheets("Out").Cells(i, 24 + k).value = Sheets("Model").Cells(firstDateRow - 7, firstPrevCol + k + 7).value
        Sheets("Out").Cells(i, 30 + k).value = Sheets("Model").Cells(firstDateRow - 6, firstPrevCol + k + 7).value
        Sheets("Out").Cells(i, 36 + k).value = Sheets("Model").Cells(firstDateRow - 2, firstObsCol + k - 1).value
    Next
End Sub

Public Sub ScaleGraph()
InterfaceOption
' Echelle automatique des graphiques
    Dim minVal As Double
    Dim maxVal As Double
    Dim midVal As Double
    minVal = Range("minObs").value + 5
    maxVal = Range("maxObs").value - 5
    midVal = (maxVal + minVal) / 2
    minVal = midVal - (midVal - minVal) / Range("ScaleRange").value
    maxVal = midVal + (maxVal - midVal) / Range("ScaleRange").value
    ActiveSheet.ChartObjects("Graphique 1").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = minVal
        .MaximumScale = maxVal
    End With
    With ActiveChart.Axes(xlValue)
        .MinimumScale = minVal
        .MaximumScale = maxVal
    End With
    ActiveSheet.ChartObjects("Graphique 75").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = minVal
        .MaximumScale = maxVal
    End With
    With ActiveChart.Axes(xlValue)
        .MinimumScale = minVal
        .MaximumScale = maxVal
    End With
    If ActiveSheet.ChartObjects("BigGraph").Visible Then
        ActiveSheet.ChartObjects("BigGraph").Visible = False
        ActiveSheet.ChartObjects("BigGraph").Visible = True
    Else
        ActiveSheet.ChartObjects("BigGraph").Visible = True
        ActiveSheet.ChartObjects("BigGraph").Visible = False
    End If
    If ActiveSheet.ChartObjects("SmallGraph").Visible Then
        ActiveSheet.ChartObjects("SmallGraph").Visible = False
        ActiveSheet.ChartObjects("SmallGraph").Visible = True
    Else
        ActiveSheet.ChartObjects("SmallGraph").Visible = True
        ActiveSheet.ChartObjects("SmallGraph").Visible = False
    End If
End Sub
Public Sub BigGraph()
InterfaceOption
    ActiveSheet.ChartObjects("SmallGraph").Visible = False
    ActiveSheet.ChartObjects("BigGraph").Visible = True
End Sub
Public Sub SmallGraph()
InterfaceOption
    ActiveSheet.ChartObjects("SmallGraph").Visible = True
    ActiveSheet.ChartObjects("BigGraph").Visible = False
End Sub
Public Sub InterfaceOption(Optional ByVal itfNb As Integer = -1)
    Dim k As Integer
    Dim i As Integer
    Dim j As Integer
    Dim n As Integer
    Dim c As Integer
    Dim s As Integer
    Dim col(1 To 30) As Integer
    Randomize
    col(1) = 3: col(2) = 4: col(3) = 5: col(4) = 6: col(5) = 7
    col(6) = 8: col(7) = 17: col(8) = 19: col(9) = 20: col(10) = 22
    col(11) = 23: col(12) = 24: col(13) = 26: col(14) = 27: col(15) = 28
    col(16) = 32: col(17) = 33: col(18) = 34: col(19) = 35: col(20) = 36
    col(21) = 37: col(22) = 38: col(23) = 39: col(24) = 40: col(25) = 41
    col(26) = 42: col(27) = 43: col(28) = 44: col(29) = 45: col(30) = 46
    If itfNb < 0 Then itfNb = Sheets("Model").Cells(3, 4).value
    Select Case itfNb
    Case 0:
    Case 1:
        n = 25 + Rnd * 100
        For k = 1 To n
            i = 1 + Int(Rnd * 45)
            j = 1 + Int(Rnd * 29)
            c = 1 + Int(Rnd * 30)
            s = 4 + Int(Rnd * 20)
            Cells(i, j).Interior.ColorIndex = col(c)
            Cells(i, j).Font.size = s
        Next
    End Select
End Sub
Public Sub InterfaceMichel()
    If Sheets("Model").Cells(3, 4).value = 1 Then
        Sheets("Model").Cells.Font.size = 10
        Sheets("Model").Cells.Interior.ColorIndex = xlNone
        Sheets("Model").Cells(3, 4).value = 0
        ActiveSheet.Shapes("Button 78").Select
        Selection.Characters.Text = "Calleja"
    Else
        Sheets("Model").Cells(3, 4).value = 1
        ActiveSheet.Shapes("Button 78").Select
        Selection.Characters.Text = "Stop !"
    End If
End Sub

