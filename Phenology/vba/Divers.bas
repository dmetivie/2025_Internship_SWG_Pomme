Attribute VB_Name = "Divers"
Option Explicit


'''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Fonctions utilitaires diverses
'''''''''''''''''''''''''''''''''''''''''''''''''''''

Public Function roundInf(ByVal x As Double, Optional nDec As Integer = 1)
    Dim y As Double
    y = 10 ^ (Int(log10(x)) - nDec)
    roundInf = y * Int(x / y)
End Function
Public Function roundSup(ByVal x As Double, Optional nDec As Integer = 1)
    Dim y As Double
    y = 10 ^ Int(log10(x) - nDec)
    roundSup = y * (Int(x / y) + 1)
End Function
Public Function log10(ByVal x As Double)
    log10 = Math.Log(x) / Math.Log(10)
End Function
Public Sub InfoBar(s As String)
    If s = "" Then Application.StatusBar = False _
    Else Application.StatusBar = s
End Sub
Public Function IsNumType(v As Variant) As Boolean
    IsNumType = (VarType(v) = vbDouble) _
             Or (VarType(v) = vbInteger) _
             Or (VarType(v) = vbLong) _
             Or (VarType(v) = vbSingle)
End Function
