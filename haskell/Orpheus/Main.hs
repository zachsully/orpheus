--------------------------------------------------------------------------------
--                                                                  2017.01.28
-- |
-- Module      :  Orpheus.Main
-- Copyright   :  Copyright (c) 2017 Zach Sullivan
-- License     :  BSD3
-- Maintainer  :  zsulliva@cs.uoregon.edu
-- Stability   :  experimental
-- Portability :  GHC-only
-- |
--
--------------------------------------------------------------------------------

module Main where

import Orpheus.Model.Discriminative
import Orpheus.DataSet
import Orpheus.Data.Feature
import Data.Monoid
import Data.MusicXML.Parser
import Options.Applicative


--------------------------------------------------------------------------------
--                             Executable Options                             --
--------------------------------------------------------------------------------
data Mode
  = Parse FilePath (Maybe FilePath)
  | Feature
  | Run
  deriving (Show,Eq)

data Options = Options { mode :: Mode }
  deriving (Show,Eq)

parseTest :: Parser Mode
parseTest = Parse
        <$> strArgument (metavar "INPUT" <> help "input musical file")
        <*> optional (strArgument (metavar "OUTPUT" <> help "xml file output"))

parseFeature :: Parser Mode
parseFeature = pure Feature

parseRun :: Parser Mode
parseRun = pure Run

options' :: Parser Mode
options' = subparser
  $  (command "parse" (info (helper <*> parseTest)
                            (progDesc "xml parser test")))
  <> (command "feature" (info (helper <*> parseFeature)
                              (progDesc "extract features from dataset")))
  <> (command "run" (info (helper <*> parseRun)
                          (progDesc "run whole orpheus pipeline")))

parseOpts :: IO Mode
parseOpts = execParser
          $ info (helper <*> options')
          $ fullDesc <> progDesc "Orpheus: disect musical scores"


--------------------------------------------------------------------------------
--                                  MAIN                                      --
--------------------------------------------------------------------------------

main :: IO ()
main = do
  m <- parseOpts
  case m of
    Parse fin fout -> do
      putStrLn "MODE: Parse"
      putStrLn $ "Parsing file " ++ fin ++ "..."
      score <- parseMusicXMLFile fin
      scoreSummary score
      case fout of
        Nothing -> putStrLn . show $ score
        Just f -> writeFile f . show $ score

    Feature -> do
      putStrLn "MODE: Feature..."
      putStrLn "Parsing dataset..."
      ds <- getDataSet
      let ds' = rPermute (length ds) ds
      putStrLn "Writing dataset/keysig.csv"
      writeFeatureSet "dataset/keysig.csv" (featureKeySig ds')
      putStrLn "Writing dataset/timesig.csv"
      writeFeatureSet "dataset/timesig.csv" (featureTimeSig ds')
      putStrLn "Writing dataset/primitive.csv"
      writeFeatureSet "dataset/primitive.csv" (featurePrimitive ds')

    Run -> do
      putStrLn "MODE: Run..."
      putStrLn "Parsing dataset..."
      ds <- getDataSet
      datasetSummary ds
      classifierSummary ds
