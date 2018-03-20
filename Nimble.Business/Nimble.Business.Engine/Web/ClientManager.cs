#region Using

using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using Nimble.Business.Engine.Common;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Server;

#endregion Using

namespace Nimble.Business.Engine.Web
{
    public class ClientManager
    {
        #region Private Members

        #region Methods

        private void Request<T>(GenericClientEntity<T> genericClientEntity)
        {
            var httpWebRequest = (HttpWebRequest)WebRequest.Create(ServiceHost + genericClientEntity.Endpoint + genericClientEntity.Method);
            httpWebRequest.Headers.Add(CustomMessageHeader.EmplacementCode.Key, CustomMessageHeader.EmplacementCode.Value);
            httpWebRequest.Headers.Add(CustomMessageHeader.ApplicationCode.Key, CustomMessageHeader.ApplicationCode.Value);
            if (!string.IsNullOrEmpty(Token?.Code))
            {
                httpWebRequest.Headers.Add(CustomMessageHeader.TokenCode.Key, Token.Code);
            }
            httpWebRequest.Method = genericClientEntity.MethodType;
            httpWebRequest.ContentType = RequestContentType;
            using (var streamWriter = new StreamWriter(httpWebRequest.GetRequestStream()))
            {
                streamWriter.Write(genericClientEntity.Json);
            }
            genericClientEntity.Headers = httpWebRequest.Headers;
            try
            {
                var webResponse = httpWebRequest.GetResponse();
                using (var responseStream = webResponse.GetResponseStream())
                {
                    if (responseStream != null)
                    {
                        var streamReader = new StreamReader(responseStream, Encoding.UTF8);
                        genericClientEntity.Entity = EngineStatic.JsonDeserialize<T>(streamReader.ReadToEnd());
                    }
                }
            }
            catch (Exception exception)
            {
                if (exception is WebException webException)
                {
                    var httpWebResponse = (HttpWebResponse)webException.Response;
                    var stream = httpWebResponse?.GetResponseStream();
                    if (stream == null)
                    {
                        genericClientEntity.Exception = webException;
                    }
                    else
                    {
                        try
                        {
                            using (var streamReader = new StreamReader(stream))
                            {
                                genericClientEntity.FaultExceptionDetail = EngineStatic.JsonDeserialize<FaultExceptionDetail>(streamReader.ReadToEnd());
                            }
                            genericClientEntity.Exception = FaultExceptionDetail.Create(genericClientEntity.FaultExceptionDetail);
                        }
                        catch
                        {
                            genericClientEntity.Exception = webException;
                        }
                    }
                }
                else
                {
                    genericClientEntity.Exception = exception;
                }
            }
        }

        private Token SetToken(Token token)
        {
            if (token != null)
            {
                Token = token;
            }
            return token;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public string ServiceHost { get; set; }

        public string RequestContentType { get; set; }

        public CustomMessageHeader CustomMessageHeader { get; set; }

        public const string Common = "Framework/Common.svc/Web/";

        public Token Token { get; set; }

        #endregion Properties

        #region Methods

        #region Common

        #region Joint

        public GenericClientEntity<Token> Login(string userCode, string userPassword)
        {
            var genericClientEntity = new GenericClientEntity<Token>
            {
                Endpoint = Common,
                Method = "Login",
                MethodType = "POST",
                Json = EngineStatic.JsonScriptSerialize(new List<KeyValuePair<string, object>>
                {
                    new KeyValuePair<string, object>("userCode", userCode),
                    new KeyValuePair<string, object>("userPassword", userPassword)
                })
            };
            Request(genericClientEntity);
            SetToken(genericClientEntity.Entity);
            return genericClientEntity;
        }

        #endregion Joint

        #region Token

        public GenericClientEntity<bool> TokenIsExpired()
        {
            var genericClientEntity = new GenericClientEntity<bool>
            {
                Endpoint = Common,
                Method = "TokenIsExpired",
                MethodType = "POST",
                Json = string.Empty
            };
            Request(genericClientEntity);
            return genericClientEntity;
        }

        #endregion Token

        #endregion Common

        #endregion Methods

        #endregion Public Members
    }
}
