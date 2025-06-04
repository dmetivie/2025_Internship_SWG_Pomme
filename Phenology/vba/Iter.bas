Attribute VB_Name = "Iter"
Option Explicit

Public Sub CMDsystematique()
    IterForm.Show
End Sub

Public Sub CMDiterer()
' Calcule les prévisions à partir des paramètres courrants en optimisant les F*
    Dim i As Integer
    Dim optJED As Boolean
    Dim optTc As Boolean
    Dim optEc As Boolean
    Dim optCx As Boolean
    Dim optJLD As Boolean
    Dim optTf As Boolean
    Dim optEf As Boolean
InterfaceOption
    Range("Comments").value = ""
    i = 3
    Do Until Sheets("Iter").Cells(i, 1).value = ""
    ' CHILLING
        If Sheets("Iter").Cells(i, 2).value = "" Then   ' Pas de vernalisation
            Sheets("Model").Range("ChilOpt").value = False
            optJED = False: optTc = False: optEc = False: optCx = False
        Else
            Sheets("Model").Range("ChilOpt").value = True
            Sheets("Model").Range("ChilTemp").value = Sheets("Iter").Cells(i, 2).value
            Sheets("Model").Range("ChilMdlNb").offSet(-1, 0).value = Sheets("Iter").Cells(i, 3).value + 1
            optJLD = False
            If Sheets("Iter").Cells(i, 4).value <> "" Then
                If IsNumeric(Sheets("Iter").Cells(i, 4).value) Then
                    Sheets("Model").Range("ChilJED").value = Sheets("Iter").Cells(i, 4).value
                    optJED = False
                Else
                    optJED = True
                End If
            End If
            If Sheets("Iter").Cells(i, 5).value <> "" Then
                If IsNumeric(Sheets("Iter").Cells(i, 5).value) Then
                    Sheets("Model").Range("ChilTc").value = Sheets("Iter").Cells(i, 5).value
                    optTc = False
                Else
                    optTc = True
                End If
            End If
            If Sheets("Iter").Cells(i, 6).value <> "" Then
                If IsNumeric(Sheets("Iter").Cells(i, 6).value) Then
                    Sheets("Model").Range("ChilEc").value = Sheets("Iter").Cells(i, 6).value
                    optEc = False
                Else
                    optEc = True
                End If
            End If
            If Sheets("Iter").Cells(i, 7).value <> "" Then
                If IsNumeric(Sheets("Iter").Cells(i, 7).value) Then
                    Sheets("Model").Range("ChilCx").value = Sheets("Iter").Cells(i, 7).value
                    optCx = False
                Else
                    optCx = True
                End If
            End If
        End If
        OPTchilling
    ' FORCING
        Sheets("Model").Range("ForcTemp").value = Sheets("Iter").Cells(i, 8).value
        Sheets("Model").Range("ForcMdlNb").offSet(-1, 0).value = Sheets("Iter").Cells(i, 9).value + 1
        If Sheets("Iter").Cells(i, 10).value <> "" Then
            If IsNumeric(Sheets("Iter").Cells(i, 10).value) Then
                Sheets("Model").Range("ForcJLD").value = Sheets("Iter").Cells(i, 10).value
                optJLD = False
            Else
                If optJED = False Then optJLD = True
            End If
        End If
        If Sheets("Iter").Cells(i, 11).value <> "" Then
            If IsNumeric(Sheets("Iter").Cells(i, 11).value) Then
                Sheets("Model").Range("ForcTf").value = Sheets("Iter").Cells(i, 11).value
                optTf = False
            Else
                optTf = True
            End If
        End If
        If Sheets("Iter").Cells(i, 12).value <> "" Then
            If IsNumeric(Sheets("Iter").Cells(i, 12).value) Then
                Sheets("Model").Range("ForcEf").value = Sheets("Iter").Cells(i, 12).value
                optEf = False
            Else
                optEf = True
            End If
        End If
    ' Ajustement
    ReadData
    SetParList optJED, optTc, optEc, optCx, optJLD, optTf, optEf
    AjustModel
    WritePara
    WriteResults
    ResultsOut
    i = i + 1
    Loop
End Sub

