Attribute VB_Name = "Action"
Option Explicit

'''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Codes des températures actives et des modèles (fonctions de réponse)
'''''''''''''''''''''''''''''''''''''''''''''''''''''

Public Function TempString(i As Integer) As String
    Select Case i
    Case 1: TempString = "Min"
    Case 2: TempString = "Moy"
    Case 3: TempString = "Max"
    End Select
End Function
Public Function ModelString(i As Integer) As String
    Select Case i
    Case 0: ModelString = "Binaire"
    Case 1: ModelString = "Linéaire"
    Case 2: ModelString = "Exponentiel"
    Case 3: ModelString = "Sigmoïde"
    Case 4: ModelString = "Triangulaire"
    Case 5: ModelString = "Parabolique"
    Case 6: ModelString = "Normal"
    End Select
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Fonctions de Reponses aux températures froides
'''''''''''''''''''''''''''''''''''''''''''''''''''''

Public Function ChillingModelDescr(modelNb As Integer) As String
' Description textuelle des modèles de chilling
    Select Case modelNb
    Case 0:    ChillingModelDescr = " = 1 si T<Tc"
    Case 1:    ChillingModelDescr = " = max(0, Tc-T)/5"
    Case 2:    ChillingModelDescr = " = exp(-T/Tc+1)"
    Case 3:    ChillingModelDescr = " = 2/[1+exp((T-Tc)/Ec)]"
    Case 4:    ChillingModelDescr = " = max(0, 1-|T-Tc|/Ec)"
    Case 5:    ChillingModelDescr = " = max(0, 1-((T-Tc)/Ec)²)"
    Case 6:    ChillingModelDescr = " = exp(-(T-Tc)²/4Ec)"
    Case Else: ChillingModelDescr = "Inconnu"
    End Select
End Function
Public Function RcMdl(T As Double, mdl As Integer, TC As Double, _
                      Optional Ec As Double = 1) As Double
' Fonctions de Chilling (normalisées telles que Rc(Tc) = 1)
    If Ec = 0 Then Ec = 0.0001
    Select Case mdl
        Case 0: RcMdl = Rc0(T, TC)
        Case 1: RcMdl = Rc1(T, TC) / 5
        Case 2: RcMdl = Rc2(T, TC) * 2.7183
        Case 3: RcMdl = Rc3(T, TC, Ec) * 2
        Case 4: RcMdl = Rc4(T, TC, Ec)
        Case 5: RcMdl = Rc5(T, TC, Ec)
        Case 6: RcMdl = Rc6(T, TC, Ec)
    End Select
End Function
Private Function Rc0(T As Double, TC As Double) As Double
' Calcul du Rc avec une fonction d'action binaire (modèle 0)
    If T < TC Then Rc0 = 1 Else Rc0 = 0
End Function
Private Function Rc1(T As Double, TC As Double) As Double
' Calcul du Rc avec une fonction d'action linéaire (modèle 1)
    If T < TC Then Rc1 = TC - T Else Rc1 = 0
End Function
Private Function Rc2(T As Double, TC As Double) As Double
' Calcul du Rc avec une fonction d'action exponentielle (modèle 2)
    If TC <> 0 Then Rc2 = Math.Exp(-T / TC) Else Rc2 = 1
End Function
Private Function Rc3(T As Double, TC As Double, Ec As Double) As Double
' Calcul du Rc avec une fonction d'action sigmoide (modèle 3)
    Rc3 = 1 / (1 + Math.Exp((T - TC) / Ec))
End Function
Private Function Rc4(T As Double, TC As Double, Ec As Double) As Double
' Calcul du Rc avec une fonction d'action triangulaire (modèle 4)
    Dim r As Double
    r = 1 - Math.Abs(TC - T) / Ec
    If r < 0 Then Rc4 = 0 Else Rc4 = r
End Function
Private Function Rc5(T As Double, TC As Double, Ec As Double) As Double
' Calcul du Rc avec une fonction d'action parabolique (modèle 5)
    Dim r As Double
    r = 1 - ((TC - T) / Ec) ^ 2
    If r < 0 Then Rc5 = 0 Else Rc5 = r
End Function
Private Function Rc6(T As Double, TC As Double, Ec As Double) As Double
' Calcul du Rc avec une fonction d'action parabolique (modèle 5)
    Rc6 = Math.Exp(-0.25 * (T - TC) ^ 2 / Ec)
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Fonctions de Reponses aux températures chaudes
'''''''''''''''''''''''''''''''''''''''''''''''''''''

Public Function ForcingModelDescr(modelNb As Integer) As String
' Description textuelle des modèles de forcing
    Select Case modelNb
    Case 0:    ForcingModelDescr = " = 1 si T>Tf"
    Case 1:    ForcingModelDescr = " = max(0, T-Tf)/5"
    Case 2:    ForcingModelDescr = " = exp(T/Tf-1)"
    Case 3:    ForcingModelDescr = " = 2/[1+exp((Tf-T)/Ef)]"
    Case 4:    ForcingModelDescr = " = max(0, 1-|T-Tf|/Ef)"
    Case 5:    ForcingModelDescr = " = max(0, 1-((T-Tf)/Ef)²)"
    Case 6:    ForcingModelDescr = " = exp(-(T-Tf)²/4Ef)"
    Case Else: ForcingModelDescr = "Inconnu"
    End Select
End Function

Public Function RfMdl(T As Double, mdl As Integer, Tf As Double, _
                      Optional Ef As Double = 1) As Double
' Fonctions de Chilling (normalisées telles que Rc(Tc) = 1)
    If Ef = 0 Then Ef = 0.0001
    Select Case mdl
        Case 0: RfMdl = Rf0(T, Tf)
        Case 1: RfMdl = Rf1(T, Tf) / 5
        Case 2: RfMdl = Rf2(T, Tf) / 2.7183
        Case 3: RfMdl = Rf3(T, Tf, Ef) * 2
        Case 4: RfMdl = Rf4(T, Tf, Ef)
        Case 5: RfMdl = Rf5(T, Tf, Ef)
        Case 6: RfMdl = Rf6(T, Tf, Ef)
    End Select
End Function
Private Function Rf0(T As Double, Tf As Double) As Double
' Calcul du Rf avec une fonction d'action binaire (modèle 0)
    If T > Tf Then Rf0 = 1 Else Rf0 = 0
End Function
Private Function Rf1(T As Double, Tf As Double) As Double
' Calcul du Sf avec une fonction d'action linéaire (modèle 1)
    If T > Tf Then Rf1 = T - Tf Else Rf1 = 0
End Function
Private Function Rf2(T As Double, Tf As Double) As Double
' Calcul du Sf avec une fonction d'action exponentielle (modèle 2)
    If Tf <> 0 Then Rf2 = Math.Exp(T / Tf) Else Rf2 = 1
End Function
Private Function Rf3(T As Double, Tf As Double, Ef As Double) As Double
' Calcul du Sf avec une fonction d'action sigmoide (modèle 3)
    Rf3 = 1 / (1 + Math.Exp((Tf - T) / Ef))
End Function
Private Function Rf4(T As Double, Tf As Double, Ef As Double) As Double
' Calcul du Sf avec une fonction d'action triangulaire (modèle 4)
    Dim r As Double
    r = 1 - Math.Abs(T - Tf) / Ef
    If r < 0 Then Rf4 = 0 Else Rf4 = r
End Function
Private Function Rf5(T As Double, Tf As Double, Ef As Double) As Double
' Calcul du Sf avec une fonction d'action parabolique (modèle 5)
    Dim r As Double
    r = 1 - ((T - Tf) / Ef) ^ 2
    If r < 0 Then Rf5 = 0 Else Rf5 = r
End Function
Private Function Rf6(T As Double, Tf As Double, Ef As Double) As Double
' Calcul du Rc avec une fonction d'action parabolique (modèle 5)
    If Ef <> 0 Then Rf6 = Math.Exp(-0.25 * (T - Tf) ^ 2 / Ef) Else Rf6 = 0
End Function


