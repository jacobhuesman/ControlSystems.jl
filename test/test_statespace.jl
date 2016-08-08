module TestStateSpace
using CustomTest
using Base.Test
using ControlSystems
# Naming convention:
# ------------------
# {type}[S]_{dims}[_d][_n]
# type: C: Continuous, D: Discrete
# scalar: add "S" if any input is scalar
# dims: "nxnuny"
# feedthrough: append "_d" if `D` is present
# names: append "_n" if some inputs/outputs/states are named

# SCALARS
a_2 = [-5 -3; 2 -9]
CS_111 = ss(-5, 2, 3, [0])
CS_111_d = ss([3], 2, 1, 1)
CS_211 = ss(a_2, [1; 2], [1 0], 0)
CS_221 = ss(a_2, [1 0; 0 2], [1 0], 0)
CS_222 = ss(a_2, [1 0; 0 2], eye(2), 0)

# CONTINUOUS
a_1 = [-5]
C_111 = ss(a_1, [2], [3], [0])
C_211 = ss(a_2, [1; 2], [1 0], [0])
C_212 = ss(a_2, [1; 2], eye(2), [0; 0])
C_221 = ss(a_2, [1 0; 0 2], [1 0], [0 0])
C_222 = ss(a_2, [1 0; 0 2], eye(2), zeros(2,2))
C_222_d = ss(a_2, [1 0; 0 2], eye(2), eye(2))
C_022 = ss(4*eye(2))

# DISCRETE
da_1 = [-0.5]
da_2 = [0.2 -0.8; -0.8 0.07]
D_111 = ss(da_1, [2], [3], [0], 0.005)
D_211 = ss(da_2, [1; 2], [1 0], [0], 0.005)
D_221 = ss(da_2, [1 0; 0 2], [1 0], [0 0], 0.005)
D_222 = ss(da_2, [1 0; 0 2], eye(2), zeros(2,2), 0.005)
D_222_d = ss(da_2, [1 0; 0 2], eye(2), eye(2), 0.005)
D_022 = ss(4*eye(2), 0.005)

# Definition of input, output and state names
C_222_d_n = ss(a_2, [1 0; 0 2], eye(2), eye(2), 
  statenames=["i","u"],inputnames=String("e"),outputnames="theta")

# TESTS
# Contstuct with scalars
@test CS_111 == C_111
@test CS_111_d == ss([3],[2],[1],[1])
@test CS_211 == C_211
@test CS_221 == C_221
@test CS_222 == C_222

# Addition
@test C_111 + C_111 == ss([-5 0; 0 -5],[2; 2],[3 3],[0])
@test C_222 + C_222 == ss([-5 -3 0 0; 2 -9 0 0; 0 0 -5 -3;
        0 0 2 -9],[1 0; 0 2; 1 0; 0 2], [1 0 1 0; 0 1 0 1],[0 0; 0 0])
@test C_222 + 1 == ss([-5 -3; 2 -9],[1 0; 0 2],[1 0; 0 1],[1 1; 1 1])
@test D_111 + D_111 == ss([-0.5 0; 0 -0.5],[2; 2],[3 3],[0], 0.005)

# Subtraction
@test C_111 - C_211 == ss([-5 0 0; 0 -5 -3; 0 2 -9],[2; 1; 2],[3 -1 -0],[0])
@test 1 - C_222 == ss([-5 -3; 2 -9],[1 0; 0 2],[-1 -0; -0 -1],[1 1; 1 1])
@test D_111 - D_211 == ss([-0.5 0 0; 0 0.2 -0.8; 0 -0.8 0.07],[2; 1; 2],
        [3 -1 -0],[0], 0.005)

# Multiplication
@test C_111 * C_221 == ss([-5 2 0; 0 -5 -3; 0 2 -9],
        [0 0; 1 0; 0 2],[3 0 0],[0 0])
@test C_212 * C_111 == ss([-5 -3 3; 2 -9 6; 0 0 -5],
        [0; 0; 2],[1 0 0; 0 1 0],[0; 0])
@test 4*C_222 == ss([-5 -3; 2 -9],[1 0; 0 2],[4 0; 0 4],[0 0; 0 0])
@test D_111 * D_221 == ss([-0.5 2 0; 0 0.2 -0.8; 0 -0.8 0.07],
        [0 0; 1 0; 0 2],[3 0 0],[0 0],0.005)

# Division
@test 1/C_222_d == ss([-6 -3; 2 -11],[1 0; 0 2],[-1 0; -0 -1],[1 -0; 0 1])
@test C_221/C_222_d == ss([-5 -3 -1 0; 2 -9 -0 -2; 0 0 -6 -3;
        0 0 2 -11],[1 0; 0 2; 1 0; 0 2],[1 0 0 0],[0 0])
@test 1/D_222_d == ss([-0.8 -0.8; -0.8 -1.93],[1 0; 0 2],[-1 0; -0 -1],
        [1 -0; 0 1],0.005)

# Indexing
@test size(C_222) == (2, 2)
@test size(C_212) == (2, 1)
@test C_222[1,1] == ss([-5 -3; 2 -9],[1; 0],[1 0],[0])
@test C_222[1:1,1] == ss([-5 -3; 2 -9],[1; 0],[1 0],[0])
@test C_222[1,1:2] == C_221
@test size(C_222[1,[]]) == (1,0)

# Naming signals
@test C_222_d_n.statenames == String["i","u"]
@test C_222_d_n.inputnames == String["e1","e2"]
@test C_222_d_n.outputnames == String["theta1","theta2"]

# Printing
res = ("StateSpace:\nA = \n          x1      x2 \n  x1   -5.0    -3.0  \n  x2"*
       "    2.0    -9.0  \nB = \n         u1     u2 \n  x1   1.0    0.0  \n"*
       "  x2   0.0    2.0  \nC = \n         x1     x2 \n  y1   1.0    0.0  \n"*
       "  y2   0.0    1.0  \nD = \n         u1     u2 \n  y1   0.0    0.0  \n"*
       "  y2   0.0    0.0  \n\nContinuous-time state-space model")
@test sprint(show, C_222) == res
res = ("StateSpace:\nA = \n          x1      x2 \n  x1    0.2    -0.8  \n  x2"*
       "   -0.8     0.07 \nB = \n         u1     u2 \n  x1   1.0    0.0  \n"*
       "  x2   0.0    2.0  \nC = \n         x1     x2 \n  y1   1.0    0.0  \n"*
       "  y2   0.0    1.0  \nD = \n         u1     u2 \n  y1   0.0    0.0  \n"*
       "  y2   0.0    0.0  \n\nSample Time: 0.005 (seconds)\n"*
       "Discrete-time state-space model")
@test sprint(show, D_222) == res
res = ("StateSpace:\nD = \n         u1     u2 \n  y1   4.0    0.0  \n  y2  "*
       " 0.0    4.0  \n\nStatic gain")
@test sprint(show, C_022) == res
res = ("StateSpace:\nD = \n         u1     u2 \n  y1   4.0    0.0  \n  y2  "*
       " 0.0    4.0  \n\nSample Time: 0.005 (seconds)\nStatic gain")
@test sprint(show, D_022) == res

# Errors
@test_throws ErrorException C_111 + C_222             # Dimension mismatch
@test_throws ErrorException C_111 - C_222             # Dimension mismatch
@test_throws ErrorException C_111 * C_222             # Dimension mismatch
@test_throws ErrorException D_111 + C_111             # Sampling time mismatch
@test_throws ErrorException D_111 - C_111             # Sampling time mismatch
@test_throws ErrorException D_111 * C_111             # Sampling time mismatch
D_diffTs = ss([1], [2], [3], [4], 0.1)
@test_throws ErrorException D_111 + D_diffTs            # Sampling time mismatch
@test_throws ErrorException D_111 - D_diffTs            # Sampling time mismatch
@test_throws ErrorException D_111 * D_diffTs            # Sampling time mismatch
@test_throws ErrorException 1/C_222                     # Not invertible
@test_throws ErrorException 1/C_212                     # Not invertible
@test_throws ErrorException ss([1 2], [1], [2], [3])      # Not square A
@test_throws ErrorException ss([1], [2 0], [1], [2])      # I/0 dim mismatch
@test_throws ErrorException ss([1], [2], [3 4], [1])      # I/0 dim mismatch
@test_throws ErrorException ss([1], [2], [3], [4], -0.1)  # Negative samping time
@test_throws ErrorException ss(eye(2), eye(2), eye(2), [0]) # Dimension mismatch
end
