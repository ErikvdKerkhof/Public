using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace game_2048
{
    class Program
    {
        static void Main()
        {
            Methods game = new Methods();
            game.New();
            ConsoleKeyInfo cki;
            Console.TreatControlCAsInput = true;
            do
            {
                game.New_num(); // generate as new number

                //reset game screen after each move
                Console.Clear(); 
                game.Display();

                // check userinput and act accordingly
                cki = Console.ReadKey();
                switch (cki.Key.ToString())
                {
                    case "A":
                        {
                            game.Move_Left();
                            game.Concastinate_Nums_Horizontal();
                            game.Move_Left();
                            break;
                        }
                    case "S":
                        {
                            game.Move_Down();
                            game.Concastinate_Nums_Vertical();
                            game.Move_Down();
                            break;
                        }
                    case "D":
                        {
                            game.Move_Right();
                            game.Concastinate_Nums_Horizontal();
                            game.Move_Right();
                            break;
                        }
                    case "W":
                        {
                            game.Move_Up();
                            game.Concastinate_Nums_Vertical();
                            game.Move_Up();
                            break;
                        }
                    case "N":
                        {
                            game.New();
                            break;
                        }
                }
            } while (cki.Key != ConsoleKey.Escape);
        }
    }


    class Methods
    {
        int dims = 4;
        int[,] array;
        Boolean win;
        Boolean loss;

        public void New()
            // this function creates an empty array to start a new game
        {
                      array = new int[dims, dims];
        }

        public void Concastinate_Nums_Horizontal()

        {
            for (int i = 0; i < array.GetLength(0); i++)
            {
                for (int j = 1; j < array.GetLength(1); j++)
                {
                    if (array[i, j] == array[i, j - 1])
                    {
                        array[i, j - 1] = 2 * array[i, j];
                        array[i, j] = 0;

                        if (array[i, j] == 2048)
                        {
                            win = true;
                        }
                    }
                }
            }
        }

        public void Concastinate_Nums_Vertical()
        {
            for (int i = 0; i < array.GetLength(0); i++)
            {
                for (int j = 1; j < array.GetLength(1); j++)
                {
                    if (array[j, i] == array[j - 1, i])
                    {
                        array[j, i] = 2 * array[j, i];
                        array[j - 1, i] = 0;

                        if (array[i, j] == 2048)
                        {
                            win = true;
                        }
                    }
                }
            }
        }

        public void Move_Left()
        {
            for (int i = 0; i < array.GetLength(0); i++)
            {
                int cnt = 0;
                for (int j = 0; j < array.GetLength(1); j++)
                {
                    if (array[i, j] != 0)
                    {
                        array[i, cnt++] = array[i, j];
                    }
                }

                while (cnt < array.GetLength(1))
                {
                    array[i, cnt++] = 0;
                }
            }
        }

        public void Move_Right()
        {
            for (int i = array.GetLength(0) - 1; i >= 0; i--)
            {
                int cnt = array.GetLength(0) - 1;
                for (int j = array.GetLength(1) - 1; j >= 0; j--)
                {
                    if (array[i, j] != 0)
                    {
                        array[i, cnt--] = array[i, j];
                    }
                }

                while (cnt >= 0)
                {
                    array[i, cnt--] = 0;
                }
            }
        }

        public void Move_Up()
        {
            for (int i = 0; i < array.GetLength(1); i++)
            {
                int cnt = 0;
                for (int j = 0; j < array.GetLength(0); j++)
                {
                    if (array[j, i] != 0)
                    {
                        array[cnt++, i] = array[j, i];
                    }
                }

                while (cnt < array.GetLength(0))
                {
                    array[cnt++, i] = 0;
                }
            }
        }

        public void Move_Down()
        {
            for (int i = array.GetLength(1) - 1; i >= 0; i--)
            {
                int cnt = array.GetLength(0) - 1;
                for (int j = array.GetLength(0) - 1; j >= 0; j--)
                {
                    if (array[j, i] != 0)
                    {
                        array[cnt--, i] = array[j, i];
                    }
                }

                while (cnt >= 0)
                {
                    array[cnt--, i] = 0;
                }
            }
        }

        public void New_num()
        {
            int cnt = 0;
            int[,] indZeros = new int[2, dims * dims];
            for (int i = 0; i < array.GetLength(0); i++)
            {
                for (int j = 0; j < array.GetLength(1); j++)
                {
                    if (array[i, j] == 0)
                    {
                        indZeros[0, cnt] = i;
                        indZeros[1, cnt] = j;
                        cnt++;
                    }
                }
            }

            if (cnt == 0)
            {
                loss = true;
                return;
            }

            Random r = new Random();
            Random n = new Random();
            int rInt = r.Next(0, cnt);
            Console.WriteLine(rInt);
            int nIntH = n.Next(0, 100);

            if (nIntH < 5)
            {
                array[indZeros[0, rInt], indZeros[1, rInt]] = 4;
            }
            else
            {
                array[indZeros[0, rInt], indZeros[1, rInt]] = 2;
            }
        }

        public void Display()
        {
            // this function displays the current game figure, game information as well as some instructions
            Console.WriteLine(" ");
            for (int i = 0; i < array.GetLength(0); i++)
            {
                for (int j = 0; j < array.GetLength(1); j++)
                {
                    Console.Write("{0}\t", array[i, j]);
                }
                Console.WriteLine(" ");
            }
            if (win)
            {
                Console.WriteLine("Congratulations, you've completed this game!");
            }

            if (loss)
            {
                Console.WriteLine("Too bad, no more moves available");
            }

            //game and control instructions
            Console.WriteLine(  "The Goal of this game is to double the numbers to 2048\n"  +
                                "when 2 equal numbers meet they will add up\n"              +
                                "Use the a,s,d,w keys to move the numbers\n"                +
                                "Press n to start a new game\n"                             +
                                "Press esc to quit the game");

        }
    }
}
