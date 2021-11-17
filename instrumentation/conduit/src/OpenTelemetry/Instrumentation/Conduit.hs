module OpenTelemetry.Instrumentation.Conduit where
import Conduit
import OpenTelemetry.Trace hiding (getTracer)
import OpenTelemetry.Trace.Monad (MonadTracer(..), MonadGetContext(..))
import Data.Text (Text)
import Control.Exception (throwIO, SomeException)

inSpan
  :: (MonadTracer m, MonadGetContext m, MonadResource m, MonadUnliftIO m) => Text
  -> CreateSpanArguments
  -> (Span -> ConduitM i o m a)
  -> ConduitM i o m a
inSpan n args f = do
  t <- lift getTracer
  ctx <- lift getContext
  bracketP
    (createSpan t ctx n args)
    (`endSpan` Nothing) $ \span -> do
      catchC (f span) $ \e -> do
        liftIO $ do
          recordException span (e :: SomeException)
          throwIO e