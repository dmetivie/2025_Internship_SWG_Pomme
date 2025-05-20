Attribute VB_Name = "Viewer"
Option Explicit

' Interfaces de la feuille View
' Feuilles utilisées : Min, Moy, Max, Pollen

Public Sub ImportViewData()
    Dim yr As String
    Dim col As Integer
    yr = Sheets("View").Range("YearView").value
    col = 2
    Do Until Sheets("Pollen").Cells(1, col).value = "" _
          Or Sheets("Pollen").Cells(1, col).value = yr
        col = col + 1
    Loop
    If Sheets("Pollen").Cells(1, col).value <> "" Then ImportDataCol col
End Sub
Public Sub NextYear()
    Dim yr As String
    Dim col As Integer
    yr = Sheets("View").Range("YearView").value
    col = 2
    Do Until Sheets("Pollen").Cells(1, col).value = "" _
          Or Sheets("Pollen").Cells(1, col).value = yr
        col = col + 1
    Loop
    col = col + 1
    If Sheets("Pollen").Cells(1, col).value <> "" Then ImportDataCol col
End Sub
Public Sub PrevYear()
    Dim yr As String
    Dim col As Integer
    yr = Sheets("View").Range("YearView").value
    col = 2
    Do Until Sheets("Pollen").Cells(1, col).value = "" _
          Or Sheets("Pollen").Cells(1, col).value = yr
        col = col + 1
    Loop
    col = col - 1
    If Sheets("Pollen").Cells(1, col).value <> "" Then ImportDataCol col
End Sub
Private Sub ImportDataCol(col As Integer)
    Dim i As Integer
    Dim k As Integer
    Dim q As Double
    Dim s As Double
    Dim keys(1 To 6) As Double
    Dim lim As Double
    Application.Calculation = xlCalculationManual
    Sheets("View").Range("YearView").value = Sheets("Pollen").Cells(1, col).value
    For i = 1 To nDays
        q = Sheets("Pollen").Cells(1 + i, col).value
        Sheets("View").Cells(1 + i, 2).value = q
        s = s + q
        Sheets("View").Cells(1 + i, 3).value = s
    Next
    q = 0
    keys(1) = 0.05: keys(2) = 0.1: keys(3) = 0.25
    keys(4) = 0.5: keys(5) = 0.75: keys(6) = 0.9
    k = 1: lim = s * keys(k)
    For i = 1 To nDays
        q = q + Sheets("Pollen").Cells(1 + i, col).value
        If q > lim Then
            Sheets("View").Cells(7, 7 + k).value = Sheets("View").Cells(1 + i, 1).value
            k = k + 1
            If k > 6 Then Exit For Else lim = s * keys(k)
        End If
    Next
    Range(Sheets("View").Cells(2, 4), Sheets("View").Cells(1 + nDays, 4)).value = _
        Range(Sheets("Min").Cells(2, col), Sheets("Min").Cells(1 + nDays, col)).value
    Range(Sheets("View").Cells(2, 5), Sheets("View").Cells(1 + nDays, 5)).value = _
        Range(Sheets("Moy").Cells(2, col), Sheets("Moy").Cells(1 + nDays, col)).value
    Range(Sheets("View").Cells(2, 6), Sheets("View").Cells(1 + nDays, 6)).value = _
        Range(Sheets("Max").Cells(2, col), Sheets("Max").Cells(1 + nDays, col)).value
    Application.Calculation = xlCalculationAutomatic
End Sub

Public Sub ScaleViews()
    Dim minDay As Long
    Dim maxDay As Long
    minDay = Sheets("ooo").Cells(10 + Cells(2, 14).value, 8)
    maxDay = Sheets("ooo").Cells(10 + Cells(4, 14).value, 8) + 31
    ActiveSheet.ChartObjects("Graphique 6").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = minDay
        .MaximumScale = maxDay
    End With
    ActiveSheet.ChartObjects("Graphique 7").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = minDay
        .MaximumScale = maxDay
    End With
    ActiveSheet.ChartObjects("Graphique 12").Activate
    With ActiveChart.Axes(xlCategory)
        .MinimumScale = minDay
        .MaximumScale = maxDay
    End With
End Sub
