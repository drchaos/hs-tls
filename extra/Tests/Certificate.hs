module Tests.Certificate
	( arbitraryX509
	) where

import Test.QuickCheck
import qualified Data.Certificate.X509 as X509
import qualified Data.Certificate.X509.Cert as X509Cert
import Control.Monad
import Data.Time.Calendar
import Data.Time.Clock (secondsToDiffTime)

readableChar :: Gen Char
readableChar = elements (['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9'])

arbitraryDN = return $ X509Cert.DistinguishedName []

arbitraryTime = do
	year   <- choose (1951, 2050)
	month  <- choose (1, 12)
	day    <- choose (1, 30)
	let days = fromGregorian year month day
	hour   <- choose (0, 23)
	minute <- choose (0, 59)
	second <- choose (0, 59)
	let seconds = secondsToDiffTime (hour * 3600 + minute * 60 + second)
	z      <- arbitrary
	return (days, seconds, z)

arbitraryX509Cert pubKey = do
	version   <- choose (1,3)
	serial    <- choose (0,2^24)
	issuerdn  <- arbitraryDN
	subjectdn <- arbitraryDN
	time1     <- arbitraryTime
	time2     <- arbitraryTime
	let sigalg = X509.SignatureALG X509.HashMD5 X509.PubKeyALG_RSA
	return $ X509Cert.Certificate
		{ X509.certVersion      = version
		, X509.certSerial       = serial
		, X509.certSignatureAlg = sigalg
		, X509.certIssuerDN     = issuerdn
		, X509.certSubjectDN    = subjectdn
		, X509.certValidity     = (time1, time2)
		, X509.certPubKey       = pubKey
		, X509.certExtensions   = Nothing
		}

arbitraryX509 pubKey = do
	cert <- arbitraryX509Cert pubKey
	sig  <- resize 40 $ listOf1 arbitrary
	let sigalg = X509.SignatureALG X509.HashMD5 X509.PubKeyALG_RSA
	return (X509.X509 cert Nothing Nothing sigalg sig)
