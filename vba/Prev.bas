Attribute VB_Name = "Prev"
Option Explicit

Public Sub CMDprevision()
    Dim DoChil As Boolean
    Dim TmpC As Integer
    Dim MdlC As Integer
    Dim JED As Double
    Dim TC As Double
    Dim Ec As Double
    Dim Cx As Double
    Dim TmpF As Integer
    Dim MdlF As Integer
    Dim JLD As Double
    Dim Tf As Double
    Dim Ef As Double
    Dim Fx(1 To 6) As Double
    Dim Sc As Double
    Dim Sf As Double
    Dim k As Integer
    Dim j As Integer
    Dim temp As Double
    Dim preJ As Date
    Dim postJ As Date
    Application.Calculation = xlCalculationManual
    ' Lecture des paramètres sur la feuille "Model"
    DoChil = Sheets("Model").Range("ChilOpt").value
    TmpC = Sheets("Model").Range("ChilTemp").value
    MdlC = Sheets("Model").Range("ChilMdlNb").value
    JED = Sheets("Model").Range("ChilJED").value + dayOffset
    TC = Sheets("Model").Range("ChilTc").value
    Ec = Sheets("Model").Range("ChilEc").value
    Cx = Sheets("Model").Range("ChilCx").value
    TmpF = Sheets("Model").Range("ForcTemp").value
    MdlF = Sheets("Model").Range("ForcMdlNb").value
    JLD = Sheets("Model").Range("ForcJLD").value + dayOffset
    Tf = Sheets("Model").Range("ForcTf").value
    Ef = Sheets("Model").Range("ForcEf").value
    For k = 1 To 6
        Fx(k) = Sheets("Model").Cells(14, 16 + k).value
    Next
    ' Calcul de la levée de dormance (chilling)
    j = 1
    If DoChil Then
        Sc = 0
        Do Until j > JED
            Cells(1 + j, 5) = Sc
            j = j + 1
        Loop
        preJ = Cells(1 + j, 1).value
        Do Until Sc > Cx Or j = nDays
            temp = Cells(1 + j, 1 + TmpC)
            Sc = Sc + RcMdl(temp, MdlC, TC, Ec)
            Cells(1 + j, 5) = Sc
            j = j + 1
        Loop
        JLD = j
        Cells(12, 11).value = Cells(1 + j, 1).value - 1
        For k = j To nDays
            Cells(1 + k, 5) = ""
        Next
    Else
        For j = 1 To nDays
            Cells(1 + j, 5) = ""
        Next
    End If
    ' Calcul de la floraison (Forcing)
    j = 1
    Sf = 0
    Do Until j > JLD
        Cells(1 + j, 6) = Sf
        j = j + 1
    Loop
    If Not DoChil Then preJ = Cells(1 + j, 1).value
    For k = 1 To 6
        Do Until Sf > Fx(k) Or j = nDays
            temp = Cells(1 + j, 1 + TmpF)
            Sf = Sf + RfMdl(temp, MdlF, Tf, Ef)
            Cells(1 + j, 6) = Sf
            j = j + 1
        Loop
        Cells(12, 11 + k).value = Cells(1 + j, 1).value - 1
    Next
    postJ = Cells(1 + j, 1).value
    For k = j To nDays
        Cells(1 + k, 6) = ""
    Next
    ' Echelle du graphique
    ActiveSheet.ChartObjects("Graphique 1").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = preJ - 15
        .MaximumScale = postJ + 15
    End With
    Application.Calculation = xlCalculationAutomatic
End Sub
